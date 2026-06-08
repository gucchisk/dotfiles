function set_openai_api_key
    set -x OPENAI_API_KEY (jq -r 'to_entries[] | select(.key | test("github.com:")) | .value | .oauth_token' ~/.config/github-copilot/apps.json)
end
