#!/usr/bin/env bash

if ! command -v jq &> /dev/null; then
  echo "Error: jq is required but not installed." >&2
  exit 1
fi

cd "$(dirname "$0")" || exit 1
mkdir -p ~/.claude

tmp_file=$(mktemp)

if [ -f ~/.claude/settings.local.json ]; then
  if jq -s '
def merge:
  reduce .[] as $item ({}; 
    reduce ($item | keys_unsorted[]) as $key (.;
      if ($item[$key] | type) == "array" then
        .[$key] = ((.[$key] // []) + $item[$key] | unique)
      elif ($item[$key] | type) == "object" then
        .[$key] = ([(.[$key] // {}), $item[$key]] | merge)
      else
        .[$key] = $item[$key]
      end
    )
  );
merge
' .claude/settings.json.base ~/.claude/settings.local.json > "$tmp_file"; then
    mv "$tmp_file" ~/.claude/settings.json
  else
    rm -f "$tmp_file"
    echo "Error: failed to merge Claude settings." >&2
    exit 1
  fi
else
  cp .claude/settings.json.base ~/.claude/settings.json
fi
