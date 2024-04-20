#!/usr/bin/env zsh

update_space() {
    SPACE_ID=$(yabai -m query --spaces --space | jq -r '.index')

    case "$SPACE_ID" in
    "7")
        ICON="7 | www"
        ;;
    "8")
        ICON="8 | dev"
        ;;
    "9")
        ICON="9 | cmd"
        ;;
    "1")
        ICON="1 | mail"
        ;;
    "2")
        ICON="2 | chat"
        ;;
    "3")
        ICON="3 | note"
        ;;
    "4")
        ICON="4 | music"
        ;;
    "5")
        ICON="5 | file"
        ;;
    "6")
        ICON="6 | priv"
        ;;
    *)
        ICON=$SPACE_ID
        ;;
    esac

    sketchybar --set $NAME \
        icon=$ICON \
        icon.padding_left=9 \
        icon.padding_right=10
}

case "$SENDER" in
"mouse.clicked")
    # Reload sketchybar
    sketchybar --remove '/.*/'
    source $HOME/.config/sketchybar/sketchybarrc
    ;;
*)
    update_space
    ;;
esac
