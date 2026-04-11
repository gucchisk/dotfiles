#!/bin/bash

# デバッグログ
LOG_FILE="/tmp/claude_switch_debug.log"
echo "=== $(date) ===" >> "$LOG_FILE"

# 引数でファイルパスを受け取る（複数セッション対応）。未指定時は旧来のパスにフォールバック
TARGET_FILE="${1:-/tmp/claude_tmux_target}"
echo "Target file: $TARGET_FILE" >> "$LOG_FILE"

# tmux情報ファイルから読み込み
if [ -f "$TARGET_FILE" ]; then
  # shellcheck source=/dev/null
  source "$TARGET_FILE"
  echo "Target: ${TMUX_TARGET_SESSION}:${TMUX_TARGET_WINDOW}" >> "$LOG_FILE"

  if pgrep -x "iTerm2" > /dev/null; then
    echo "Using iTerm2" >> "$LOG_FILE"

    # iTerm2の場合 - current tab は read-only のため select コマンドでタブを切り替える
    APPLESCRIPT_RESULT=$(osascript 2>&1 <<EOF
tell application "iTerm2"
  set targetTabIdx to -1
  set targetWinIdx to -1
  set winIdx to 0

  repeat with w in windows
    set winIdx to winIdx + 1
    set tabIdx to 0
    repeat with t in tabs of w
      set tabIdx to tabIdx + 1
      set sessionName to name of current session of t
      if sessionName contains "${TMUX_TARGET_WINDOW_NAME}" or (sessionName contains "tmux" and sessionName contains "${TMUX_TARGET_DIR}") then
        set targetTabIdx to tabIdx
        set targetWinIdx to winIdx
        exit repeat
      end if
    end repeat
    if targetTabIdx is not -1 then exit repeat
  end repeat

  if targetTabIdx is not -1 then
    select tab targetTabIdx of window targetWinIdx
    activate
    return "switched to tab " & targetTabIdx & " of window " & targetWinIdx
  else
    activate
    return "no matching tab found"
  end if
end tell
EOF
)
    echo "AppleScript result: $APPLESCRIPT_RESULT" >> "$LOG_FILE"

    # 使用済みのターゲットファイルを削除
    rm -f "$TARGET_FILE"

    # tmuxのウィンドウも切り替え（フルパス指定でPATH問題を回避）
    TMUX_BIN="/opt/homebrew/bin/tmux"
    if [ ! -x "$TMUX_BIN" ]; then
      TMUX_BIN="/usr/local/bin/tmux"
    fi
    if [ -x "$TMUX_BIN" ]; then
      echo "Executing tmux select-window..." >> "$LOG_FILE"
      "$TMUX_BIN" select-window -t "${TMUX_TARGET_SESSION}:${TMUX_TARGET_WINDOW}" 2>> "$LOG_FILE"
      echo "Tmux window switched!" >> "$LOG_FILE"
    else
      echo "tmux not found" >> "$LOG_FILE"
    fi
  else
    echo "Using Terminal.app" >> "$LOG_FILE"
    # Terminal.appの場合
    TMUX_BIN="/opt/homebrew/bin/tmux"
    if [ ! -x "$TMUX_BIN" ]; then
      TMUX_BIN="/usr/local/bin/tmux"
    fi
    osascript 2>> "$LOG_FILE" <<EOF
tell application "Terminal"
    activate
    do script "${TMUX_BIN} select-window -t ${TMUX_TARGET_SESSION}:${TMUX_TARGET_WINDOW}" in front window
end tell
EOF
    rm -f "$TARGET_FILE"
  fi
else
  echo "No target file found: $TARGET_FILE" >> "$LOG_FILE"
fi
