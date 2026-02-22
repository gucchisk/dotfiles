function tmi -d 'Create new iTerm2 window and attach to or create tmux session with iTerm2 integration'
  set session_name (basename $PWD)
  set current_dir $PWD
  osascript \
      -e "tell application \"iTerm2\"" \
      -e "create window with default profile" \
      -e "tell current session of current window" \
      -e "write text \"cd $current_dir\"" \
      -e "write text \"tmux -CC attach -t $session_name || tmux -CC new -s $session_name\"" \
      -e "end tell" \
      -e "end tell"
end
