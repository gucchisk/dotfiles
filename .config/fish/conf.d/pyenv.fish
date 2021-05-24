if set -q use_pyenv; and $use_pyenv
   status is-login; and pyenv init --path | source
   pyenv init - | source
end