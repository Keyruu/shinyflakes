#!/bin/bash

# write this into a proper bash script
# echo 'test man' && sleep 5 && yabai -m query --windows --window $YABAI_WINDOW_ID | jq '.space' | xargs -I {} echo \"alt - {}\"

ID=$YABAI_WINDOW_ID

SPACE_ID=$(yabai -m query --windows --window $ID | jq '.space')

skhd --key "alt - $SPACE_ID"

yabai -m window --focus $ID
