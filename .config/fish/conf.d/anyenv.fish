if type -q anyenv
    status --is-interactive; and source (anyenv init -|psub)
end
