#!/bin/bash

homedir=$(cd $(dirname $0); pwd)
dotfilelist=(.emacs .emacs.d/elisp .emacs.d/conf .gitconfig .emacs.d/custom.el)
dotfiledirlist=(.config/fish/functions .config/fish/conf.d)

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
