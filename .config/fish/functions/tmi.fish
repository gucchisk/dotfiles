# function tmi
#   set session_name (basename $PWD)
#   if tmux has-session -t "$session_name" 2>/dev/null
#     tmux -CC attach -t "$session_name" &; disown
#   else
#     tmux -CC new -s "$session_name" &; disown
#   end
# end
function tmi
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
