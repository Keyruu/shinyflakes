{...}: {
  home.file.".config/skhd/skhdrc".text =
    /*
    bash
    */
    ''
      ctrl - e : yabai -m space --layout bsp; sketchybar --trigger yabai_change
      ctrl - s : yabai -m space --layout stack; sketchybar --trigger yabai_change

      # Navigation
      alt - h : yabai -m window --focus west
      alt - j : yabai -m window --focus south
      alt - k : yabai -m window --focus north
      alt - l : yabai -m window --focus east
      alt - n : yabai -m window --focus stack.next || yabai -m window --focus stack.first
      alt - p : yabai -m window --focus stack.prev || yabai -m window --focus stack.last

      # Moving windows
      shift + alt - h : yabai -m window --swap west
      shift + alt - j : yabai -m window --swap south
      shift + alt - k : yabai -m window --swap north
      shift + alt - l : yabai -m window --swap east

      # Move focus between spaces
      alt - 1 : $HOME/.config/yabai/focusSpace.sh 1
      alt - 2 : $HOME/.config/yabai/focusSpace.sh 2
      alt - 3 : $HOME/.config/yabai/focusSpace.sh 3
      alt - 4 : $HOME/.config/yabai/focusSpace.sh 4
      alt - 5 : $HOME/.config/yabai/focusSpace.sh 5
      alt - 6 : $HOME/.config/yabai/focusSpace.sh 6
      alt - 7 : $HOME/.config/yabai/focusSpace.sh 7
      alt - 8 : $HOME/.config/yabai/focusSpace.sh 8
      alt - 9 : $HOME/.config/yabai/focusSpace.sh 9

      alt - 0 : yabai -m query --spaces --space recent | jq .index | xargs -I {} $HOME/.config/yabai/focusSpace.sh {}

      # Move focus container to workspace
      shift + alt - 1 : $HOME/.config/yabai/sendToSpace.sh 1
      shift + alt - 2 : $HOME/.config/yabai/sendToSpace.sh 2
      shift + alt - 3 : $HOME/.config/yabai/sendToSpace.sh 3
      shift + alt - 4 : $HOME/.config/yabai/sendToSpace.sh 4
      shift + alt - 5 : $HOME/.config/yabai/sendToSpace.sh 5
      shift + alt - 6 : $HOME/.config/yabai/sendToSpace.sh 6
      shift + alt - 7 : $HOME/.config/yabai/sendToSpace.sh 7
      shift + alt - 8 : $HOME/.config/yabai/sendToSpace.sh 8
      shift + alt - 9 : $HOME/.config/yabai/sendToSpace.sh 9

      # Focus apps
      alt - c : open -a Arc
      alt - e : open -a WezTerm
      alt - d : open -a Finder
      alt - a : open -a "Slack"
      alt - m : open -a "Spotify.app"
      alt - t : open -a "Microsoft Teams"
      # alt - i : yabai -m window --toggle heynote && $HOME/shinyflakes/darwin/home/yabai/focusApp.sh Heynote || open -a "Heynote"
      alt - w : open -a "Obsidian"
      alt - o : open -a "Microsoft Outlook"
      alt - v : open -a "IntelliJ IDEA Ultimate"
      alt - g : open raycast://extensions/ricoberger/gitmoji/gitmoji


      # Resize windows
      lctrl + alt - h : yabai -m window --resize left:-50:0; \
                        yabai -m window --resize right:-50:0
      lctrl + alt - j : yabai -m window --resize bottom:0:50; \
                        yabai -m window --resize top:0:50
      lctrl + alt - k : yabai -m window --resize top:0:-50; \
                        yabai -m window --resize bottom:0:-50
      lctrl + alt - l : yabai -m window --resize right:50:0; \
                        yabai -m window --resize left:50:0

      # Equalize size of windows
      lctrl + alt - e : yabai -m space --balance

      # Enable / Disable gaps in current workspace
      lctrl + alt - g : yabai -m space --toggle padding; yabai -m space --toggle gap

      # Rotate windows clockwise and anticlockwise
      alt - r         : yabai -m space --rotate 270
      shift + alt - r : yabai -m space --rotate 90

      # Rotate on X and Y Axis
      shift + alt - x : yabai -m space --mirror x-axis
      shift + alt - y : yabai -m space --mirror y-axis

      # Set insertion point for focused container
      # shift + lctrl + alt - h : yabai -m window --insert west
      # shift + lctrl + alt - j : yabai -m window --insert south
      # shift + lctrl + alt - k : yabai -m window --insert north
      # shift + lctrl + alt - l : yabai -m window --insert east

      # Float / Unfloat window
      shift + alt - space : \
          yabai -m window --toggle float; \
          yabai -m window --toggle border

      # Restart Yabai
      shift + lctrl + alt - r : \
          /usr/bin/env osascript <<< \
              "display notification \"Restarting Yabai\" with title \"Yabai\""; \
          yabai --restart-service && sleep 2 && $HOME/.config/yabai/default.sh

      shift - play : spotify_player playback play-pause
      shift - next : spotify_player playback next
      shift - previous : spotify_player playback previous

      shift + lctrl + alt - d : $HOME/.config/yabai/default.sh

      # Make window native fullscreen
      alt - f         : yabai -m window --toggle zoom-fullscreen; sketchybar --trigger fullscreen
      shift + alt - f : yabai -m window --toggle native-fullscreen
    '';
}
