function tm
  set session_name (basename $PWD)
  set current_dir $PWD
  tmux attach -t $session_name || tmux new -s $session_name
end
