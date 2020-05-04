#!/bin/bash

homedir=$(cd $(dirname $0); pwd)
dotfilelist=(.emacs .emacs.d/elisp .emacs.d/conf .gitconfig)

ls $(cd $(dirname $0); pwd)/.config/fish/functions/ | xargs -I{} ln -s $(cd $(dirname $0); pwd)/.config/fish/functions/{} ~/.config/fish/functions/{}
ls $(cd $(dirname $0); pwd)/.config/fish/conf.d/ | xargs -I{} ln -s $(cd $(dirname $0); pwd)/.config/fish/conf.d/{} ~/.config/fish/conf.d/{}

for file in ${dotfilelist[@]}; do
    src=$homedir/$file
    dist=~/$file
    if [ ! -L $dist ]; then
	ln -s $src $dist
    fi
done
