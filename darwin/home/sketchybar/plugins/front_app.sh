#!/usr/bin/env zsh

ICON_PADDING_RIGHT=5
WINDOW=$(yabai -m query --windows --window)
INFO=$(echo $WINDOW | jq -r '.app')
WINDOW_TITLE=$(echo $WINDOW | jq -r '.title')
TITLE="$INFO | $WINDOW_TITLE"

case $INFO in
"Code")
    ICON_PADDING_RIGHT=4
    ICON=󰨞
    ;;
"Calendar")
    ICON_PADDING_RIGHT=3
    ICON=
    ;;
"Discord")
    ICON=󰙯
    ;;
"FaceTime")
    ICON_PADDING_RIGHT=5
    ICON=
    ;;
"Finder")
    ICON=󰀶
    ;;
"Arc")
    ICON=
    ;;
"IINA")
    ICON_PADDING_RIGHT=4
    ICON=󰕼
    ;;
"kitty")
    ICON=󰄛
    ;;
"Warp")
    ICON=󰆍
    ;;
"Messages")
    ICON=󰍦
    ;;
"Obsidian")
    ICON_PADDING_RIGHT=6
    ICON=󰈄
    ;;
"Preview")
    ICON_PADDING_RIGHT=3
    ICON=
    ;;
"Spotify")
    ICON=
    ;;
"TextEdit")
    ICON_PADDING_RIGHT=4
    ICON=
    ;;
"Transmission")
    ICON_PADDING_RIGHT=3
    ICON=󰶘
    ;;
"Slack")
    ICON=󰒱
    ;;
"Microsoft Outlook")
    ICON=󰴢
    ;;
"Microsoft Teams (work or school)")
    ICON=󰊻
    ;;
"IntelliJ IDEA")
    ICON=
    ;;
"IntelliJ IDEA-EAP")
    ICON=
    ;;
*)
    ICON=﯂
    ;;
esac

# W I N D O W  T I T L E 

if [[ ${#TITLE} -gt 60 ]]; then
  TITLE="$(echo "$TITLE" | cut -c 1-60)…"
fi

sketchybar --set $NAME icon=$ICON icon.padding_right=$ICON_PADDING_RIGHT
sketchybar --set $NAME.name label="$TITLE"
