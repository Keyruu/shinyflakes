{ config, pkgs, ... }:
{
  programs.alacritty = {
    enable = true;
    package = pkgs.alacritty-graphics;
    theme = "dracula";
    settings = {
      window = {
        opacity = 0.9;
        decorations = "Buttonless";
        padding = {
          x = 10;
          y = 10;
        };
      };
      font = {
        normal = {
          family = config.user.font;
        };
        size = 13;
      };
      colors = {
        primary = {
          background = "#100F0F";
        };
      };
      bell = {
        color = "#003753";
        duration = 200;
      };
      hints.enabled = [
        {
          command = "xdg-open";
          hyperlinks = true;
          post_processing = true;
          persist = false;
          regex = "(mailto:|https://|http://|file://)[^\\u0000-\\u001F\\u007F-\\u009F<>\"\\s{-}\\^⟨⟩\`$]+";
          binding = {
            key = "E";
            mods = "Control|Shift";
          };
        }
      ];
      keyboard.bindings = [
        {
          key = "N";
          mods = "Super";
          action = "CreateNewWindow";
        }
      ];
    };
  };
}
