if set -q use_anyenv; and $use_anyenv
    status --is-interactive; and source (anyenv init -|psub)
end