{ pkgs, ... }:
{
  programs.alacritty = {
    enable = true;
    package = pkgs.alacritty-graphics;
    theme = "dracula";
    settings = {
      window = {
        decorations = "Buttonless";
        padding = {
          x = 10;
          y = 10;
        };
      };
      font = {
        normal = {
          family = "JetBrainsMono Nerd Font";
        };
        size = 12;
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
