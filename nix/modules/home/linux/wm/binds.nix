{
  wayland.windowManager.sway.config = rec {
    modifier = "Alt"; # Same as Hyprland $mod

    terminal = "wezterm";
    menu = "tofi-drun | xargs swaymsg exec --";

    keybindings = {
      # Application shortcuts
      "${modifier}+e" = "workspace number 3; exec focusOrOpen wezterm org.wezfurlong.wezterm";
      "${modifier}+c" = "workspace number 1; exec focusOrOpen zen zen";
      "${modifier}+v" = "workspace number 2; exec focusOrOpen zeditor dev.zed.Zed";
      # "${modifier}+m" =
      #   "workspace number 4; exec focusOrOpen \"foot --app-id spotify_player spotify_player\" spotify_player";
      "${modifier}+m" = "workspace number 4; exec focusOrOpen spotify";
      "${modifier}+a" = "workspace number 5; exec focusOrOpen slack Slack";
      "${modifier}+w" = "exec focusOrOpen obsidian obsidian";

      # "Super+u" = "mode umlaut";
      "${modifier}+s" = "exec wtype ß";

      # Window management (vim-style navigation)
      "${modifier}+h" = "focus left";
      "${modifier}+j" = "focus down";
      "${modifier}+k" = "focus up";
      "${modifier}+l" = "focus right";
      "${modifier}+Shift+h" = "move left";
      "${modifier}+Shift+j" = "move down";
      "${modifier}+Shift+k" = "move up";
      "${modifier}+Shift+l" = "move right";

      # Arrow key alternatives
      "${modifier}+Left" = "focus left";
      "${modifier}+Down" = "focus down";
      "${modifier}+Up" = "focus up";
      "${modifier}+Right" = "focus right";
      "${modifier}+Shift+Left" = "move left";
      "${modifier}+Shift+Down" = "move down";
      "${modifier}+Shift+Up" = "move up";
      "${modifier}+Shift+Right" = "move right";

      # Window actions
      "Super+q" = "kill"; # Close window (matching Hyprland $otherMod)
      "${modifier}+t" = "floating toggle";
      "${modifier}+f" = "fullscreen toggle";
      "${modifier}+Tab" = "vicinae vicinae://extensions/vicinae/wm/switch-windows";
      "${modifier}+Comma" = "layout toggle stacking tabbed";
      "${modifier}+Period" = "layout toggle splitv splith";

      # Launchers and utilities
      "Super+space" = "exec vicinae toggle";
      "${modifier}+space" = "exec scratch";
      "Super+Shift+space" =
        "exec 1password --ozone-platform-hint=wayland --quick-access --enable-features=UseOzonePlatform,WebRTCPipeWireCapturer,WaylandWindowDecorations";
      "Super+Shift+l" = "exec loginctl lock-session";
      "Super+Shift+v" = "exec vicinae vicinae://extensions/vicinae/clipboard/history";
      "Super+x" = "exec wl-kbptr -c $HOME/.config/wl-kbptr/floating";

      # Screenshots
      "Print" = "exec grim -g \"$(slurp)\" - | wl-copy";
      "Super+Shift+4" = "exec grim -g \"$(slurp)\" - | wl-copy";

      # Copy/paste shortcuts
      "Super+c" = "exec copyPasteShortcut copy org.wezfurlong.wezterm dev.zed.Zed foot scratchpad";
      "Super+v" = "exec copyPasteShortcut paste org.wezfurlong.wezterm dev.zed.Zed foot scratchpad";
      "Super+a" = "exec wtype -M ctrl -k a";
      "Super+t" = "exec wtype -M ctrl -k t";
      "Super+k" = "exec wtype -M ctrl -k k";
      "Super+w" = "exec wtype -M ctrl -k w";
      "Super+r" = "exec wtype -M ctrl -k r";
      "Super+f" = "exec wtype -M ctrl -k f";

      # Layout
      # "${modifier}+v" = "splitv";
      # "${modifier}+b" = "splith";

      # Resize mode
      "${modifier}+r" = "mode resize";

      # Workspace switching (1-9)
    }
    // builtins.listToAttrs (
      builtins.concatLists (
        builtins.genList (
          i:
          let
            ws = toString (i + 1);
          in
          [
            {
              name = "${modifier}+${ws}";
              value = "workspace number ${ws}";
            }
            {
              name = "${modifier}+Shift+${ws}";
              value = "move container to workspace number ${ws}; workspace number ${ws}";
            }
          ]
        ) 9
      )
    );

    # Resize mode
    modes = {
      resize = {
        "h" = "resize shrink width 10px";
        "j" = "resize grow height 10px";
        "k" = "resize shrink height 10px";
        "l" = "resize grow width 10px";
        "Left" = "resize shrink width 10px";
        "Down" = "resize grow height 10px";
        "Up" = "resize shrink height 10px";
        "Right" = "resize grow width 10px";
        "w" = "exec ultrawide";
        "Return" = "mode default";
        "Escape" = "mode default";
      };
      umlaut = {
        "a" = "exec type-umlaut ä, mode default";
        "o" = "exec type-umlaut ö, mode default";
        "u" = "exec type-umlaut ü, mode default";
        "Shift+a" = "exec type-umlaut Ä, mode default";
        "Shift+o" = "exec type-umlaut Ö, mode default";
        "Shift+u" = "exec type-umlaut Ü, mode default";
        "Escape" = "mode default";
        "Return" = "mode default";
        "Control+g" = "mode default";
      };
    };
  };
}
