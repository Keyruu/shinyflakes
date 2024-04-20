#!/bin/bash

# Identify all Chrome windows
windows=$(yabai -m query --windows | jq -r '.[] | select(.app == "'"$1"'") | .id')

# Loop through each window and move it to space 7
for window_id in $windows; do
    yabai -m window $window_id --space $2
done
