{ pkgs, ... }:
{
  wayland.windowManager.hyprland = {
    settings = {
      binds = {
        movefocus_cycles_fullscreen = true;
      };
      "$mod" = "Alt";
      "$otherMod" = "Super";
      "$terminal" = "wezterm";
      "$fileManager" = "dolphin";
      "$menu" = "wofi --show drun";

      bind =
        [
          "$mod, E, exec, focusOrOpen wezterm org.wezfurlong.wezterm"
          "$mod, C, exec, focusOrOpen zen zen"
          "$mod, M, exec, focusOrOpen \"foot --app-id spotify_player spotify_player\" spotify_player"
          "$mod, W, exec, focusOrOpen obsidian obsidian"
          # "$mod, H, hy3:movefocus, l"
          # "$mod, J, hy3:movefocus, d"
          # "$mod, K, hy3:movefocus, u"
          # "$mod, L, hy3:movefocus, r"
          # "$mod Shift, H, hy3:movewindow, l"
          # "$mod Shift, J, hy3:movewindow, d"
          # "$mod Shift, K, hy3:movewindow, u"
          # "$mod Shift, L, hy3:movewindow, r"
          "$mod, H, movefocus, l"
          "$mod, J, movefocus, d"
          "$mod, K, movefocus, u"
          "$mod, L, movefocus, r"
          "$mod Shift, H, movewindow, l"
          "$mod Shift, J, movewindow, d"
          "$mod Shift, K, movewindow, u"
          "$mod Shift, L, movewindow, r"
          "$mod Shift, U, movecurrentworkspacetomonitor, u"
          "$mod Shift, D, movecurrentworkspacetomonitor, d"
          # "$mod, slash, hy3:changegroup, opposite"
          # "$mod, comma, hy3:changegroup, toggletab"
          ", Print, exec, grimblast copy area"
          "$otherMod, Space, exec, sherlock"
          "$otherMod Shift, Space, exec, tofi"
          "$otherMod, X, exec, powermenu"
          "$otherMod Shift, L, exec, pidof hyprlock || ${pkgs.hyprlock}/bin/hyprlock"
          "$otherMod Shift, V, exec, foot --app-id clipse sh -c clipse"
          "$otherMod Shift, 4, exec, hyprshot -m region --clipboard-only"

          "$otherMod, C, exec, copyPasteShortcut copy org.wezfurlong.wezterm"
          "$otherMod, V, exec, copyPasteShortcut paste org.wezfurlong.wezterm"
          "$otherMod, A, sendshortcut, CTRL,A,"
          "$otherMod, T, sendshortcut, CTRL,T,"
          "$otherMod, W, sendshortcut, CTRL,W,"

          "$otherMod, Q, killactive," # Close window
          "$mod, T, togglefloating," # Toggle Floating
          "$mod, F, fullscreenstate, 1"
          # "$mod, tab, exec, hyprswitch gui --mod-key alt --key tab --close mod-key-release --reverse-key=key=shift --sort-recent && hyprswitch dispatch"
          # "$mod Shift, tab, exec, hyprswitch gui --mod-key alt --key tab --close mod-key-release --reverse-key=key=shift --sort-recent && hyprswitch dispatch -r"
          "$mod, Tab, workspace, previous"
          "$otherMod, Tab, exec, walker --modules=windows"
        ]
        ++ (
          # workspaces
          # binds $mod + [shift +] {1..9} to [move to] workspace {1..9}
          builtins.concatLists (
            builtins.genList (
              i:
              let
                ws = i + 1;
              in
              [
                "$mod, code:1${toString i}, workspace, ${toString ws}"
                "$mod SHIFT, code:1${toString i}, movetoworkspace, ${toString ws}"
              ]
            ) 9
          )
        );

      bindm = [
        "$mod,mouse:272, movewindow" # Move Window (mouse)
        "$mod,R, resizewindow" # Resize Window (mouse)
      ];

      bindl = [
        ",XF86AudioMute, exec, sound-toggle" # Toggle Mute
        ",XF86AudioPlay, exec, ${pkgs.playerctl}/bin/playerctl play-pause" # Play/Pause Song
        ",XF86AudioNext, exec, ${pkgs.playerctl}/bin/playerctl next" # Next Song
        ",XF86AudioPrev, exec, ${pkgs.playerctl}/bin/playerctl previous" # Previous Song
        ",switch:Lid Switch, exec, pidof hyprlock || ${pkgs.hyprlock}/bin/hyprlock" # Lock when closing Lid
      ];

      bindle = [
        ",XF86AudioRaiseVolume, exec, sound-up" # Sound Up
        ",XF86AudioLowerVolume, exec, sound-down" # Sound Down
        ",XF86MonBrightnessUp, exec, brightness-up" # Brightness Up
        ",XF86MonBrightnessDown, exec, brightness-down" # Brightness Down
      ];
    };
    extraConfig =
      let
        keysStr = "sdsfzvcxwerqtyihlkjknm";

        keyChars = builtins.genList (i: builtins.substring i 1 keysStr) (builtins.stringLength keysStr);

        bindLines = builtins.map (
          key: "bind = , ${key}, exec, wtype ${key}\nbind = , ${key}, submap, reset"
        ) keyChars;
      in
      ''
        bind = $mod, S, exec, wtype ß
        bind = $mod, U, submap, umlaut

        submap = umlaut

        bind = , a, exec, wtype ä
        bind = , a, submap, reset
        bind = , u, exec, wtype ü
        bind = , u, submap, reset
        bind = , o, exec, wtype ö
        bind = , o, submap, reset

        ${builtins.concatStringsSep "\n" bindLines}
        bind = , comma, exec, wtype ,
        bind = , comma, submap, reset
        bind = , dot, exec, wtype .
        bind = , dot, submap, reset
        bind = , semicolon, exec, wtype ;
        bind = , semicolon, submap, reset
        bind = , escape, submap, reset

        submap = reset
      '';
  };
}
