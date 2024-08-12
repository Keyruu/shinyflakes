#!/usr/bin/env zsh

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title New Zellij Tab - Project
# @raycast.mode silent

# Optional parameters:
# @raycast.icon 🤖
# @raycast.argument1 { "type": "text", "placeholder": "zoxide query" }

dir=$(eval "zoxide query $1")
if [ -z "$dir" ]; then
    echo "No directory found"
    exit 1
fi
zellij action new-tab -l project -c "$dir"
echo "Opened new tab in $dir"
