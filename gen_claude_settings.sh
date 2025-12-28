#!/bin/bash

if [ -f ~/.claude/settings.json.local ]; then

jq -s '
  def merge:
    reduce .[] as $item ({}; 
      reduce ($item | keys_unsorted[]) as $key (.;
        if ($item[$key] | type) == "array" then
          .[$key] = ((.[$key] // []) + $item[$key] | unique)
        elif ($item[$key] | type) == "object" then
          .[$key] = ([.[$key], $item[$key]] | merge)
        else
          .[$key] = $item[$key]
        end
      )
    );
  merge
' .claude/settings.json.base ~/.claude/settings.json.local > ~/.claude/settings.json
else
  cp .claude/settings.json.base ~/.claude/setting.json
fi
