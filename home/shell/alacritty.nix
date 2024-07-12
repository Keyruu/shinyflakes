{...}: {
  programs.alacritty = {
    enable = true;
    settings = {
      window = {
        decorations = "Buttonless";
        opacity = 0.7;
        padding = {
          x = 10;
          y = 10;
        };
      };
      font = {
        normal = {
          family = "JetBrainsMono Nerd Font";
        };
        size = 14;
      };
      colors = {
        primary = {
          background = "#011627";
        };

      normal = {
        black = "#586069";
        red = "#ea4a5a";
        green = "#34d058";
        yellow = "#ffea7f";
        blue = "#2188ff";
        magenta = "#b392f0";
        cyan = "#39c5cf";
        white = "#d1d5da";
      };

      bright = {
        black = "#959da5";
        red = "#f97583";
        green = "#85e89d";
        yellow = "#ffea7f";
        blue = "#79b8ff";
        magenta = "#b392f0";
        cyan = "#56d4dd";
        white = "#fafbfc";
      };
      };
      bell = {
        color = "#003753";
        duration = 200;
      };
    };
  };
}
