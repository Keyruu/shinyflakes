{...}: {
  wayland.windowManager.hyprland = {
    enable = true;
    settings = {
      "$mod" = "ALT";
      "$terminal" = "wezterm";
      "$fileManager" = "dolphin";
      "$menu" = "wofi --show drun";

      animations = {
        enabled = "no";
      };

      bind =
        [
          "$mod, E, exec, $terminal"
          "$mod, C, exec, firefox"
          "$mod, H, movefocus, l"
          "$mod, J, movefocus, d"
          "$mod, K, movefocus, u"
          "$mod, L, movefocus, r"
          ", Print, exec, grimblast copy area"
        ]
        ++ (
          # workspaces
          # binds $mod + [shift +] {1..9} to [move to] workspace {1..9}
          builtins.concatLists (builtins.genList (i:
              let ws = i + 1;
              in [
                "$mod, code:1${toString i}, workspace, ${toString ws}"
                "$mod SHIFT, code:1${toString i}, movetoworkspace, ${toString ws}"
              ]
            )
            9)
        );
    };
  };
}
