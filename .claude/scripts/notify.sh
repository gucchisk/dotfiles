#!/bin/bash

# 入力からメッセージを取得
INPUT=$(cat)
MESSAGE=$(echo "$INPUT" | jq -r '.message // "入力待ち"')

# ファイル名に埋め込む値から、パス区切りやシェルのメタ文字になりうる文字を落とす
sanitize_path_component() {
  printf '%s' "$1" | tr -c '[:alnum:]._-' '_'
}

# 状態ファイルは所有者だけがアクセスできるディレクトリに置く。
# パスは予測可能なので、他ユーザーが先回りして用意したディレクトリを掴んでいないか
# 使う前に確かめる。条件を満たさない場合は書き込まずに失敗させる。
create_state_dir() {
  local state_dir="${TMPDIR:-/tmp}/claude-tmux-state"
  mkdir -p "$state_dir" || return 1
  chmod 700 "$state_dir" || return 1

  # 実ディレクトリであること（シンボリックリンク経由で別の場所に書かされないため）
  [ -d "$state_dir" ] && [ ! -L "$state_dir" ] || return 1

  local owner_uid dir_perms
  owner_uid=$(stat -f '%u' "$state_dir" 2>/dev/null) || return 1
  dir_perms=$(stat -f '%Lp' "$state_dir" 2>/dev/null) || return 1
  [ "$owner_uid" = "$(id -u)" ] || return 1
  [ "$dir_perms" = "700" ] || return 1

  printf '%s' "$state_dir"
}

# 状態ファイルはJSONで書き出す。シェルの代入文として保存すると、
# ウィンドウ名やディレクトリ名に含まれる文字が読み込み側でコードとして実行されうるため。
# 同一ディレクトリ内にmktempで作ってからmvすることで、権限を絞ったまま原子的に差し替える。
write_state_file() {
  local target_file="$1"
  local json_content="$2"
  local tmp_file
  tmp_file=$(mktemp "$(dirname "$target_file")/.target.XXXXXX") || return 1
  chmod 600 "$tmp_file"
  printf '%s\n' "$json_content" > "$tmp_file"
  mv -f "$tmp_file" "$target_file"
}

# 通知クリック時に前面へ出すアプリのbundle IDを判定する。
# pgrepでのプロセス列挙はフックの実行環境（Herdr配下など）によっては
# 権限やプロセスツリーの都合で失敗することがあるため、まず端末自身が
# 設定するTERM_PROGRAMを信頼し、pgrepは補助的なフォールバックとして使う。
detect_bundle_id() {
  if [ "$TERM_PROGRAM" = "iTerm.app" ] || pgrep -x "iTerm2" > /dev/null 2>&1; then
    printf 'com.googlecode.iterm2'
  else
    printf 'com.apple.Terminal'
  fi
}

# Herdr (https://herdr.dev) 配下で実行されている場合。
# Herdrは既存のiTerm2タブの中にTUIとして描画される独自マルチプレクサーで、
# `herdr agent focus`は対象paneをherdr内部で選択状態にするだけでOSレベルの
# タブ切り替えやウィンドウ前面化は行わない。そのためiTerm2のタブ選択自体は
# 従来通りセッションUUID($ITERM_SESSION_ID)によるAppleScriptマッチングで行い、
# 追加でherdr側のpane選択も合わせて行う。
if [ "${HERDR_ENV:-}" = "1" ] && [ -n "${HERDR_PANE_ID:-}" ]; then
  HERDR_BIN="${HERDR_BIN_PATH:-herdr}"
  BUNDLE_ID=$(detect_bundle_id)
  ITERM_UUID="${ITERM_SESSION_ID#*:}"
  echo "$(date): notify.sh (herdr) BUNDLE_ID=$BUNDLE_ID PANE_ID=$HERDR_PANE_ID HERDR_BIN=$HERDR_BIN ITERM_UUID=$ITERM_UUID" >> /tmp/claude_switch_debug.log
  EXEC_CMD="/bin/bash '${HOME}/.claude/scripts/herdr_focus.sh' '${HERDR_PANE_ID}' '${HERDR_BIN}' '${ITERM_UUID}'"
  terminal-notifier \
    -title "Claude Code" \
    -message "$MESSAGE" \
    -sound "Glass" \
    -activate "$BUNDLE_ID" \
    -execute "$EXEC_CMD"
  exit 0
fi

# 現在のtmux情報を取得
if [ -n "$TMUX" ]; then
  # -t を付けずにdisplay-messageを呼ぶと「クライアントが今表示しているpane」が返るため、
  # ユーザーが別ウィンドウを見ている間に通知が出ると誤ったウィンドウが記録されてしまう。
  # フックが継承している $TMUX_PANE を明示指定して、Claude Codeが動いているpaneを確実に指す。
  TMUX_TARGET_SPEC="${TMUX_PANE:-}"
  if [ -n "$TMUX_TARGET_SPEC" ]; then
    TMUX_INFO=$(tmux display-message -p -t "$TMUX_TARGET_SPEC" '#S'$'\t''#I'$'\t''#W'$'\t''#D')
  else
    TMUX_INFO=$(tmux display-message -p '#S'$'\t''#I'$'\t''#W'$'\t''#D')
  fi
  IFS=$'\t' read -r TMUX_SESSION TMUX_WINDOW TMUX_WINDOW_NAME TMUX_PANE_ID <<< "$TMUX_INFO"

  # tmux情報をpaneごとに一意なファイルに保存（switch_tmux.shが読み込む）
  # ウィンドウ番号は変動するのでファイル名にも不変なpane IDを使う
  CURRENT_DIR=$(basename "$PWD")
  PANE_ID_SUFFIX="${TMUX_PANE_ID#%}"
  STATE_DIR=$(create_state_dir) || {
    echo "$(date): notify.sh aborted, state dir is not usable" >> /tmp/claude_switch_debug.log
    exit 1
  }
  TARGET_FILE="${STATE_DIR}/target_$(sanitize_path_component "$TMUX_SESSION")_pane${PANE_ID_SUFFIX}.json"

  # このtmuxセッションに接続しているクライアントのTTYを取得（iTerm2とのマッチングに使用）。
  # フックからは通知元のクライアントを直接特定できないため、同じセッションに複数の
  # クライアントが繋がっている場合は最後に操作されたものを選ぶ。
  TMUX_CLIENT_TTY=$(tmux list-clients -t "${TMUX_SESSION}:" -F '#{client_activity}'$'\t''#{client_tty}' 2>/dev/null \
    | sort -rn | head -1 | cut -f2)
  write_state_file "$TARGET_FILE" "$(jq -n \
    --arg session "$TMUX_SESSION" \
    --arg window "$TMUX_WINDOW" \
    --arg window_name "$TMUX_WINDOW_NAME" \
    --arg pane "$TMUX_PANE_ID" \
    --arg dir "$CURRENT_DIR" \
    --arg client_tty "$TMUX_CLIENT_TTY" \
    '{tmux_target_session: $session,
      tmux_target_window: $window,
      tmux_target_window_name: $window_name,
      tmux_target_pane: $pane,
      tmux_target_dir: $dir,
      tmux_client_tty: $client_tty,
      iterm_session_uuid: ""}')"

  BUNDLE_ID=$(detect_bundle_id)

  EXEC_CMD="/bin/bash '${HOME}/.claude/scripts/switch_tmux.sh' '${TARGET_FILE}'"
  echo "$(date): notify.sh sending notification, EXEC_CMD=$EXEC_CMD" >> /tmp/claude_switch_debug.log
  # terminal-notifierで通知を表示
  # 通知クリック時にswitch_tmux.shを実行（対象ファイルパスを引数で渡す）
  terminal-notifier \
    -title "Claude Code" \
    -message "$MESSAGE" \
    -sound "Glass" \
    -activate "$BUNDLE_ID" \
    -execute "$EXEC_CMD"
else
  # tmux外の場合: iTerm2のセッションIDでタブを特定して切り替える
  ITERM_UUID="${ITERM_SESSION_ID#*:}"
  STATE_DIR=$(create_state_dir) || {
    echo "$(date): notify.sh aborted, state dir is not usable" >> /tmp/claude_switch_debug.log
    exit 1
  }
  TARGET_FILE="${STATE_DIR}/target_itermsession_$(sanitize_path_component "$ITERM_UUID").json"
  write_state_file "$TARGET_FILE" "$(jq -n --arg iterm_uuid "$ITERM_UUID" \
    '{tmux_target_session: "",
      tmux_target_window: "",
      tmux_target_window_name: "",
      tmux_target_pane: "",
      tmux_target_dir: "",
      tmux_client_tty: "",
      iterm_session_uuid: $iterm_uuid}')"

  BUNDLE_ID=$(detect_bundle_id)

  EXEC_CMD="/bin/bash '${HOME}/.claude/scripts/switch_tmux.sh' '${TARGET_FILE}'"
  terminal-notifier \
    -title "Claude Code" \
    -message "$MESSAGE" \
    -sound "Glass" \
    -activate "$BUNDLE_ID" \
    -execute "$EXEC_CMD"
fi

# tmux内でもメッセージを表示
if [ -n "$TMUX" ]; then
  tmux display-message "⚠️  Claude Code: $MESSAGE"
fi
