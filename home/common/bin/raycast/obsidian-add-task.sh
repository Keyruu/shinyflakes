#!/usr/bin/env bash

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Add Task
# @raycast.mode silent

# Optional parameters:
# @raycast.icon 🪨
# @raycast.argument1 { "type": "text", "placeholder": "Task" }

encoded=$(echo "$1" | jq "@uri" -jRr)
open -g "obsidian://quickadd?choice=add-task-uri&value-content=$encoded"
