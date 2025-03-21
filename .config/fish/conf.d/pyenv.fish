if type -q pyenv
    status is-login; and pyenv init --path | source
    pyenv init - | source
end
