#!/bin/bash
# INPUT=$(cat)
# MESSAGE=$(echo "$INPUT" | jq -r '.message // "入力待ち"')
# osascript -e "display notification \"$MESSAGE\" with title \"Claude Code\""
printf '\e]9;\a'
printf '\e]1337;RequestAttention=1\a'
osascript -e 'display alert "⚠️ Claude Code" message "入力が必要です" as critical buttons {"確認"} default button 1'
# osascript -e 'tell application "iTerm2" to activate' 2>/dev/null
