#!/bin/bash

ln -s $(cd $(dirname $0); pwd)/.emacs ~/.emacs
ls $(cd $(dirname $0); pwd)/.config/fish/functions/ | xargs -I{} ln -s $(cd $(dirname $0); pwd)/.config/fish/functions/{} ~/.config/fish/functions/{}
