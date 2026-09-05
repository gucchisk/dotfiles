#!/bin/bash

# 通知クリック時にHerdr管理下の対象paneへフォーカスを戻す。
# terminal-notifierの-executeはクリック時に非対話的に実行されるため、
# 実行されたかどうか・herdrコマンドが成功したかどうかを追えるようログを残す。
LOG_FILE="/tmp/claude_switch_debug.log"
echo "=== $(date) (herdr_focus.sh) ===" >> "$LOG_FILE"

PANE_ID="$1"
HERDR_BIN="${2:-herdr}"
ITERM_UUID="$3"

echo "PANE_ID=$PANE_ID HERDR_BIN=$HERDR_BIN ITERM_UUID=$ITERM_UUID PATH=$PATH" >> "$LOG_FILE"

# herdrはtmuxのような外部プロセスをラップせず、自身のTUIとして
# 既存のiTerm2タブの中に描画される。そのためherdrのセッション自体を
# アクティブにするには、まずherdrクライアントが動いているiTerm2タブを
# OSレベルで前面に出す必要がある（herdr agent focusはherdr内部の
# 状態管理だけを行い、iTerm2のタブ切り替えやウィンドウ前面化はしない）。
if [ -n "$ITERM_UUID" ]; then
  APPLESCRIPT_RESULT=$(osascript 2>&1 - "$ITERM_UUID" <<'EOF'
on run argv
  set targetUuid to item 1 of argv
  set foundWin to 0
  set foundTab to 0

  tell application "iTerm2"
    set winCount to count of windows
    repeat with i from 1 to winCount
      set tabCount to count of tabs of window i
      repeat with j from 1 to tabCount
        set sessionCount to count of sessions of tab j of window i
        repeat with k from 1 to sessionCount
          if id of session k of tab j of window i is targetUuid then
            set foundWin to i
            set foundTab to j
          end if
        end repeat
      end repeat
    end repeat

    if foundWin is 0 then
      activate
      return "no matching tab found"
    end if

    set index of window foundWin to 1
    activate
  end tell

  -- set current tab が iTerm2 3.6では使えないため、
  -- System Events のキーストローク (Cmd+タブ番号) でタブを切り替える
  delay 0.3
  tell application "System Events"
    tell process "iTerm2"
      keystroke (foundTab as string) using command down
    end tell
  end tell

  return "switched win=" & foundWin & " tab=" & foundTab
end run
EOF
)
  echo "AppleScript result: $APPLESCRIPT_RESULT" >> "$LOG_FILE"
else
  echo "ITERM_UUID not provided, just activating iTerm2" >> "$LOG_FILE"
  osascript -e 'tell application "iTerm2" to activate' >> "$LOG_FILE" 2>&1
fi

# herdr内で複数pane/tabに分かれている場合に備え、対象paneを
# herdr自身のTUI上でも選択状態にする
RESULT=$("$HERDR_BIN" agent focus "$PANE_ID" 2>&1)
STATUS=$?
echo "herdr agent focus exit=$STATUS result=$RESULT" >> "$LOG_FILE"
