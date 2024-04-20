yabai -m signal --add event=window_focused action="sketchybar --trigger window_focused"
yabai -m signal --add event=window_title_changed action="sketchybar --trigger window_title_changed"

# ===== Rules ==================================

yabai -m rule --add label="Arc" app="^Arc$" space=^7
yabai -m rule --add label="IntelliJ" app="^IntelliJ IDEA.*" space=^8
yabai -m rule --add label="Warp" app="^Warp$" space=^9
yabai -m rule --add label="Kitty" app="^kitty$" space=^9
yabai -m rule --add label="Alacritty" app="^Alacritty$" space=^9
yabai -m rule --add label="Outlook" app="^Microsoft Outlook$" space=^1
yabai -m rule --add label="Teams" app="^Microsoft Teams (work or school)$" space=^2
yabai -m rule --add label="Slack" app="^Slack$" space=^2
yabai -m rule --add label="Obsidian" app="^Obsidian$" space=^3
yabai -m rule --add label="Heynote" app="^Heynote$" space=^3
yabai -m rule --add label="Spotify" app="^Spotify$" space=^4
yabai -m rule --add label="Path Finder" app="^Path Finder$" space=^5
yabai -m rule --add label="Messages" app="^Messages$" space=^6

yabai -m signal --add label="Change Space after launch" event=window_created action="$HOME/.config/yabai/changeSpaceAfterCreation.sh"

yabai -m rule --add label="Parallels" app="^Parallels Desktop$" manage=off
yabai -m rule --add label="iTerm" app="^IntelliJ IDEA.*" title="^Push Commits .*" manage=off
yabai -m rule --add label="Safari" app="^Safari$" title="^(General|(Tab|Password|Website|Extension)s|AutoFill|Se(arch|curity)|Privacy|Advance)$" manage=off
yabai -m rule --add label="System Settings" app="^System Settings$" title=".*" manage=off
yabai -m rule --add label="Finder" app="^Finder$" manage=off
yabai -m rule --add label="App Store" app="^App Store$" manage=off
yabai -m rule --add label="Activity Monitor" app="^Activity Monitor$" manage=off
yabai -m rule --add label="KeePassXC" app="^KeePassXC$" manage=off
yabai -m rule --add label="Calculator" app="^Calculator$" manage=off
yabai -m rule --add label="Dictionary" app="^Dictionary$" manage=off
yabai -m rule --add label="Software Update" title="Software Update" manage=off
yabai -m rule --add label="About This Mac" app="System Information" title="About This Mac" manage=off
yabai -m rule --add label="Raycast" app="^Raycast$" title=".*" manage=off

# float settings windows
yabai -m rule --add title='Settings$' manage=off

echo "yabai configuration loaded.."

