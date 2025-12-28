#!/bin/bash

if [ -f ~/.claude/settings.json.local ]; then
  jq -s '.[0] * .[1]' .claude/settings.json.base ~/.claude/settings.json.local > ~/.claude/settings.json
else
  cp .claude/settings.json.base ~/.claude/setting.json
fi
