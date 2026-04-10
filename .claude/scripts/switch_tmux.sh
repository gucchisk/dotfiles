#!/bin/bash

# デバッグログ
LOG_FILE="/tmp/claude_switch_debug.log"
echo "=== $(date) ===" >> "$LOG_FILE"

# tmux情報ファイルから読み込み
if [ -f /tmp/claude_tmux_target ]; then
  # shellcheck source=/dev/null
  source /tmp/claude_tmux_target
  echo "Target: ${TMUX_TARGET_SESSION}:${TMUX_TARGET_WINDOW}" >> "$LOG_FILE"

  if pgrep -x "iTerm2" > /dev/null; then
    # shellcheck disable=SC2129
    echo "Using iTerm2" >> "$LOG_FILE"
    # iTerm2の場合 - ウィンドウ名またはディレクトリ名でtmuxタブを特定
    osascript <<EOF >> "$LOG_FILE" 2>&1
tell application "iTerm2"
  log "Searching for tab: window_name=${TMUX_TARGET_WINDOW_NAME} dir=${TMUX_TARGET_DIR}"

  -- すべてのウィンドウとタブを検索
  set targetWindow to missing value
  set targetTab to missing value

  repeat with w in windows
    repeat with t in tabs of w
      set s to current session of t
      tell s
        set sessionName to name
        -- tmux -CC モード: ウィンドウ名で一致
        -- 通常tmuxモード: "tmux" + ディレクトリ名で一致
        if sessionName contains "${TMUX_TARGET_WINDOW_NAME}" or (sessionName contains "tmux" and sessionName contains "${TMUX_TARGET_DIR}") then
          log "Found: " & sessionName
          set targetWindow to w
          set targetTab to t
          exit repeat
        end if
      end tell
    end repeat
    if targetWindow is not missing value then exit repeat
  end repeat

  if targetWindow is not missing value then
    -- タブを選択してからウィンドウを前面に出す
    tell targetWindow
      set current tab to targetTab
      select
    end tell
    activate
  else
    log "No matching tab found"
    activate
  end if
end tell
EOF
    echo "AppleScript executed" >> "$LOG_FILE"

    # tmuxコマンドをバックグラウンドで実行（画面に表示されない）
    echo "Executing tmux command in background..." >> "$LOG_FILE"
    tmux select-window -t "${TMUX_TARGET_SESSION}:${TMUX_TARGET_WINDOW}" 2>> "$LOG_FILE"
    echo "Tmux window switched!" >> "$LOG_FILE"
  else
    echo "Using Terminal.app" >> "$LOG_FILE"
    # Terminal.appの場合
    osascript <<EOF 2>> "$LOG_FILE"
tell application "Terminal"
    activate
    do script "tmux select-window -t ${TMUX_TARGET_SESSION}:${TMUX_TARGET_WINDOW}" in front window
end tell
EOF
  fi
else
  echo "No target file found" >> "$LOG_FILE"
fi
