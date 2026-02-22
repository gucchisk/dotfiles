function tm -d 'Attach to or create tmux session based on current directory name'
  set session_name (basename $PWD)
  tmux attach -t "$session_name" || tmux new -s "$session_name"
end
