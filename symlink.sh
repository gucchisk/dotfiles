#!/bin/bash

homedir=$(cd $(dirname $0); pwd)
dotfilelist=(.emacs .emacs.d/elisp .emacs.d/conf .gitconfig .emacs.d/custom.el .claude/scripts .tmux.conf .claude/settings.json)
dotfiledirlist=(.config/fish/functions .config/fish/conf.d .claude/skills)

for dir in ${dotfiledirlist[@]}; do
  files=$(ls $dir)
  for file in $files; do
    dotfilelist+=( $dir/$file )
  done
done

for file in ${dotfilelist[@]}; do
  src=$homedir/$file
  dist=~/$file
  if [ ! -L $dist ]; then
    ln -s $src $dist
  fi
done

# cage
if [[ "$(uname -s)" == "Darwin" ]]; then
  cagedir="$HOME/Library/Application Support/cage"
elif [[ "$(uname -s)" == "Linux" ]]; then
  cagedir="$HOME/.config/cage"
fi
if [ ! -L "$cagedir" ]; then
  ln -s "$homedir/cage" "$cagedir"
fi
