#!/bin/zsh

fullscreen=$(yabai -m query --windows --window | jq -r '."has-fullscreen-zoom"')

case "$fullscreen" in
    true)
    sketchybar -m --set yabai_fullscreen label="󰊓" drawing=on
    ;;
    false)
    sketchybar -m --set yabai_fullscreen drawing=off
    ;;
esac
