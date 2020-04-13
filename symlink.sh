#!/bin/bash

ln -s $(cd $(dirname $0); pwd)/.emacs ~/.emacs
ls $(cd $(dirname $0); pwd)/.config/fish/functions/ | xargs -I{} ln -s $(cd $(dirname $0); pwd)/.config/fish/functions/{} ~/.config/fish/functions/{}
ln -s $(cd $(dirname $0); pwd)/.emacs.d/elisp ~/.emacs.d/elisp
ln -s $(cd $(dirname $0); pwd)/.emacs.d/custom.el ~/.emacs.d/custom.el
ln -s $(cd $(dirname $0); pwd)/.gitconfig ~/.gitconfig
