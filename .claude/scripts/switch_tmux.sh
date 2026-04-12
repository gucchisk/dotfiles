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
  echo "Target: ${TMUX_TARGET_SESSION}:${TMUX_TARGET_WINDOW}, TTY: ${TMUX_CLIENT_TTY}" >> "$LOG_FILE"

  if pgrep -x "iTerm2" > /dev/null; then
    echo "Using iTerm2" >> "$LOG_FILE"

    # iTerm2の場合 - TTYマッチングを優先し、フォールバックとして名前マッチングを使用
    APPLESCRIPT_RESULT=$(osascript 2>&1 - "$TMUX_CLIENT_TTY" "$TMUX_TARGET_WINDOW_NAME" "$TMUX_TARGET_DIR" <<'EOF'
on run argv
  set targetTty to item 1 of argv
  set targetWindowName to item 2 of argv
  set targetDir to item 3 of argv

  tell application "iTerm2"
    -- TTYで直接マッチング（tmuxクライアントとiTerm2セッションを紐付ける最も確実な方法）
    if targetTty is not "" then
      set winIdx to 0
      repeat with w in windows
        set winIdx to winIdx + 1
        set tabIdx to 0
        repeat with t in tabs of w
          set tabIdx to tabIdx + 1
          repeat with s in sessions of t
            if tty of s is targetTty then
              select tab tabIdx of window winIdx
              activate
              return "switched by TTY to tab " & tabIdx & " of window " & winIdx
            end if
          end repeat
        end repeat
      end repeat
      -- TTYが指定されていたが見つからなかった場合はリトライのため失敗を返す
      return "tty_not_found"
    end if

    -- TTYが未指定の場合のみ: タブ名によるマッチング
    set winIdx to 0
    repeat with w in windows
      set winIdx to winIdx + 1
      set tabIdx to 0
      repeat with t in tabs of w
        set tabIdx to tabIdx + 1
        set sessionName to name of current session of t
        if sessionName contains targetWindowName or (sessionName contains "tmux" and sessionName contains targetDir) then
          select tab tabIdx of window winIdx
          activate
          return "switched by name to tab " & tabIdx & " of window " & winIdx
        end if
      end repeat
    end repeat

    activate
    return "no matching tab found"
  end tell
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
