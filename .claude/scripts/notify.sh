#!/bin/bash

# 入力からメッセージを取得
INPUT=$(cat)
MESSAGE=$(echo "$INPUT" | jq -r '.message // "入力待ち"')

# ファイル名に埋め込む値から、パス区切りやシェルのメタ文字になりうる文字を落とす
sanitize_path_component() {
  printf '%s' "$1" | tr -c '[:alnum:]._-' '_'
}

# 状態ファイルは所有者だけがアクセスできるディレクトリに置く。
# /tmp直下は他ユーザーが同名ファイルを先回りして作れてしまい、
# 読み込み側が細工された内容を掴まされる余地が残るため使わない。
create_state_dir() {
  local state_dir="${TMPDIR:-/tmp}/claude-tmux-state"
  mkdir -p "$state_dir"
  chmod 700 "$state_dir"
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
  STATE_DIR=$(create_state_dir)
  TARGET_FILE="${STATE_DIR}/target_$(sanitize_path_component "$TMUX_SESSION")_pane${PANE_ID_SUFFIX}.json"

  # このtmuxセッションに接続しているクライアントのTTYを取得（iTerm2とのマッチングに使用）
  TMUX_CLIENT_TTY=$(tmux list-clients -t "${TMUX_SESSION}:" -F '#{client_tty}' 2>/dev/null | head -1)
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

  # iTerm2とTerminal.appの判定
  if pgrep -x "iTerm2" > /dev/null; then
    BUNDLE_ID="com.googlecode.iterm2"
  else
    BUNDLE_ID="com.apple.Terminal"
  fi

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
  STATE_DIR=$(create_state_dir)
  TARGET_FILE="${STATE_DIR}/target_itermsession_$(sanitize_path_component "$ITERM_UUID").json"
  write_state_file "$TARGET_FILE" "$(jq -n --arg iterm_uuid "$ITERM_UUID" \
    '{tmux_target_session: "",
      tmux_target_window: "",
      tmux_target_window_name: "",
      tmux_target_pane: "",
      tmux_target_dir: "",
      tmux_client_tty: "",
      iterm_session_uuid: $iterm_uuid}')"

  if pgrep -x "iTerm2" > /dev/null; then
    BUNDLE_ID="com.googlecode.iterm2"
  else
    BUNDLE_ID="com.apple.Terminal"
  fi

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
