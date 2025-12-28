#!/bin/bash

if [ -f ~/.claude/settings.json.local ]; then
  jq -s '
reduce .[] as $item ({}; 
  reduce ($item | keys[]) as $key (.;
    if ($item[$key] | type) == "array" 
    then .[$key] = ((.[$key] // []) + $item[$key])
    else .[$key] = $item[$key]
    end
  )
)' .claude/settings.json.base ~/.claude/settings.json.local > ~/.claude/settings.json
else
  cp .claude/settings.json.base ~/.claude/setting.json
fi
