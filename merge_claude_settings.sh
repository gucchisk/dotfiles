#!/usr/bin/env bash

if ! command -v jq &> /dev/null; then
  echo "Error: jq is required but not installed." >&2
  exit 1
fi

cd "$(dirname "$0")" || exit 1
mkdir -p ~/.claude

if [ -f ~/.claude/settings.local.json ]; then
  jq -s '
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
' .claude/settings.json ~/.claude/settings.local.json > ~/.claude/settings.json
else
  cp .claude/settings.json ~/.claude/settings.json
fi
