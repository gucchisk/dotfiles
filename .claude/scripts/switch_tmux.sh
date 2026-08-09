#!/bin/bash

# デバッグログ
LOG_FILE="/tmp/claude_switch_debug.log"
echo "=== $(date) ===" >> "$LOG_FILE"

# 引数でファイルパスを受け取る（複数セッション対応）。未指定時は旧来のパスにフォールバック
TARGET_FILE="${1:-/tmp/claude_tmux_target}"
echo "Target file: $TARGET_FILE" >> "$LOG_FILE"

# 切り替え先を決める。ウィンドウ番号は並び替え・削除で変動するため、不変のpane IDを優先する。
# display-messageは存在しないpaneを渡しても終了コード0を返してしまうので、
# 実在するpane IDの一覧と突き合わせて判定する。
resolve_switch_target() {
  local tmux_bin="$1" pane_id="$2" session="$3" window="$4"
  if [ -n "$pane_id" ] && "$tmux_bin" list-panes -a -F '#D' 2>/dev/null | grep -qxF "$pane_id"; then
    printf '%s' "$pane_id"
  else
    printf '%s' "${session}:${window}"
  fi
}

# tmux情報ファイルから読み込み
if [ -f "$TARGET_FILE" ]; then
  # 状態ファイルはJSON。sourceで読み込むとファイルの中身がそのままシェルコードとして
  # 実行されてしまうため、許可したキーだけをjqで取り出して変数に入れる。
  STATE_TSV=$(jq -r '[.tmux_target_session,
                      .tmux_target_window,
                      .tmux_target_window_name,
                      .tmux_target_pane,
                      .tmux_target_dir,
                      .tmux_client_tty,
                      .iterm_session_uuid]
                     | map(if type == "string" then . else "" end)
                     | @tsv' "$TARGET_FILE" 2>> "$LOG_FILE")

  if [ -z "$STATE_TSV" ]; then
    echo "Invalid or unreadable state file: $TARGET_FILE" >> "$LOG_FILE"
    exit 1
  fi

  IFS=$'\t' read -r TMUX_TARGET_SESSION \
                   TMUX_TARGET_WINDOW \
                   TMUX_TARGET_WINDOW_NAME \
                   TMUX_TARGET_PANE \
                   TMUX_TARGET_DIR \
                   TMUX_CLIENT_TTY \
                   ITERM_SESSION_UUID <<< "$STATE_TSV"

  echo "Target: ${TMUX_TARGET_SESSION}:${TMUX_TARGET_WINDOW}, TTY: ${TMUX_CLIENT_TTY}" >> "$LOG_FILE"

  if pgrep -x "iTerm2" > /dev/null; then
    echo "Using iTerm2" >> "$LOG_FILE"

    # iTerm2の場合 - セッションID(UUID)マッチングを最優先し、TTY、タブ名の順にフォールバック
    APPLESCRIPT_RESULT=$(osascript 2>&1 - "$TMUX_CLIENT_TTY" "$TMUX_TARGET_WINDOW_NAME" "$TMUX_TARGET_DIR" "$ITERM_SESSION_UUID" <<'EOF'
on run argv
  set targetTty to item 1 of argv
  set targetWindowName to item 2 of argv
  set targetDir to item 3 of argv
  set targetUuid to item 4 of argv

  set foundWin to 0
  set foundTab to 0
  -- タブ内が分割されている場合、一致したsessionを選ばないと別の分割にフォーカスが残るため
  -- 何番目のsessionが一致したかも覚えておく
  set foundSession to 0

  tell application "iTerm2"
    set winCount to count of windows
    -- セッションID(UUID)で直接マッチング
    if targetUuid is not "" then
      repeat with i from 1 to winCount
        set tabCount to count of tabs of window i
        repeat with j from 1 to tabCount
          set sessionCount to count of sessions of tab j of window i
          repeat with k from 1 to sessionCount
            if id of session k of tab j of window i is targetUuid then
              set foundWin to i
              set foundTab to j
              set foundSession to k
            end if
          end repeat
        end repeat
      end repeat
    end if

    -- TTYで直接マッチング
    if foundWin is 0 and targetTty is not "" then
      repeat with i from 1 to winCount
        set tabCount to count of tabs of window i
        repeat with j from 1 to tabCount
          set sessionCount to count of sessions of tab j of window i
          repeat with k from 1 to sessionCount
            if tty of session k of tab j of window i is targetTty then
              set foundWin to i
              set foundTab to j
              set foundSession to k
            end if
          end repeat
        end repeat
      end repeat
    end if

    -- 見つからない場合: タブ名によるマッチング
    if foundWin is 0 then
      repeat with i from 1 to winCount
        set tabCount to count of tabs of window i
        repeat with j from 1 to tabCount
          set sessionName to name of current session of tab j of window i
          if sessionName contains targetWindowName or (sessionName contains "tmux" and sessionName contains targetDir) then
            set foundWin to i
            set foundTab to j
          end if
        end repeat
      end repeat
    end if

    if foundWin is 0 then
      activate
      return "no matching tab found"
    end if

    -- 対象ウィンドウを最前面に出す（複数ウィンドウ環境で誤ったウィンドウのタブが
    -- 切り替わってしまうのを防ぐため、activateだけに頼らず明示的に選択する）
    set index of window foundWin to 1
    activate

    -- UUID/TTYで特定できた場合は、そのsession自体も選択する。
    -- タブ選択とsession選択は独立しているため、これがないと分割タブでは
    -- 通知元ではなく元々アクティブだった分割にフォーカスが残る。
    -- タブ名マッチ(foundSessionが0)の場合は特定できていないので触らない。
    if foundSession is not 0 then
      try
        select session foundSession of tab foundTab of window foundWin
      end try
    end if
  end tell

  -- set current tab が iTerm2 3.6では使えないため、
  -- System Events のキーストローク (Cmd+タブ番号) でタブを切り替える
  delay 0.3
  tell application "System Events"
    tell process "iTerm2"
      keystroke (foundTab as string) using command down
    end tell
  end tell

  return "switched win=" & foundWin & " tab=" & foundTab & " session=" & foundSession
end run
EOF
)
    echo "AppleScript result: $APPLESCRIPT_RESULT" >> "$LOG_FILE"

    # TTYが指定されていたが見つからなかった場合はTARGET_FILEを保持してリトライを可能にする
    if [ "$APPLESCRIPT_RESULT" = "tty_not_found" ]; then
      echo "TTY not found, keeping target file for retry" >> "$LOG_FILE"
    else
      # 成功またはTTY未指定の場合のみターゲットファイルを削除してtmuxウィンドウを切り替える
      rm -f "$TARGET_FILE"

      # tmux外(通常のiTermタブ)から発火した通知の場合はtmux切り替え不要
      if [ -n "$TMUX_TARGET_SESSION" ]; then
        # tmuxのウィンドウも切り替え（フルパス指定でPATH問題を回避）
        TMUX_BIN="/opt/homebrew/bin/tmux"
        if [ ! -x "$TMUX_BIN" ]; then
          TMUX_BIN="/usr/local/bin/tmux"
        fi
        if [ -x "$TMUX_BIN" ]; then
          SWITCH_TARGET=$(resolve_switch_target "$TMUX_BIN" "$TMUX_TARGET_PANE" "$TMUX_TARGET_SESSION" "$TMUX_TARGET_WINDOW")
          echo "Executing tmux select-window (target=$SWITCH_TARGET)..." >> "$LOG_FILE"
          "$TMUX_BIN" select-window -t "$SWITCH_TARGET" 2>> "$LOG_FILE"
          # 同一ウィンドウ内に複数paneがある場合に該当paneへフォーカスを合わせる
          "$TMUX_BIN" select-pane -t "$SWITCH_TARGET" 2>> "$LOG_FILE"
          echo "Tmux window switched!" >> "$LOG_FILE"
        else
          echo "tmux not found" >> "$LOG_FILE"
        fi
      fi
    fi
  else
    echo "Using Terminal.app" >> "$LOG_FILE"
    # Terminal.appの場合
    TMUX_BIN="/opt/homebrew/bin/tmux"
    if [ ! -x "$TMUX_BIN" ]; then
      TMUX_BIN="/usr/local/bin/tmux"
    fi
    # iTerm2側と同じ判定で切り替え先を決める
    SWITCH_TARGET=$(resolve_switch_target "$TMUX_BIN" "$TMUX_TARGET_PANE" "$TMUX_TARGET_SESSION" "$TMUX_TARGET_WINDOW")
    echo "Executing tmux select-window (target=$SWITCH_TARGET)..." >> "$LOG_FILE"
    osascript 2>> "$LOG_FILE" <<EOF
tell application "Terminal"
    activate
    do script "${TMUX_BIN} select-window -t ${SWITCH_TARGET}; ${TMUX_BIN} select-pane -t ${SWITCH_TARGET}" in front window
end tell
EOF
    rm -f "$TARGET_FILE"
  fi
else
  echo "No target file found: $TARGET_FILE" >> "$LOG_FILE"
fi
