{ config, pkgs, ... }: {
  programs.rofi = {
    enable = true;
    plugins = with pkgs; [rofi-calc rofi-emoji];
    font = "monospace 13";
    extraConfig = {
      modi = "window,drun,run,emoji,calc";
      show-icons = true;
      show-match = true;
      icon-theme = "Qogir";
      drun-display-format = "{name}";
      window-format = "{t}";
      display-drun = " ";
      display-run = " ";
      display-window = " ";
    };
    theme = let
      inherit (config.lib.formats.rasi) mkLiteral;
    in {
      "*" = {
        bg = mkLiteral "#080808";
        fg = mkLiteral "#e4e4e4";
        background-color = mkLiteral "transparent";
        text-color = mkLiteral "@fg";
        margin = 0;
        padding = 0;
        spacing = 0;
      };
      window = {
        location = mkLiteral "center";
        width = 480;
        border = mkLiteral "2px";
        border-color = mkLiteral "@fg";
      };
      "inputbar, textbox, window" = {
        background-color = mkLiteral "@bg";
      };
      "prompt, entry, element-cion, element-text" = {
        vertical-align = mkLiteral "0.5";
      };
      textbox = {
        padding = mkLiteral "8px";
      };
      listview = {
        padding = mkLiteral "4px 0";
        lines = 8;
        columns = 1;
        fixed-height = false;
      };
      "element, inputbar" = {
        padding = mkLiteral "8px";
        spacing = mkLiteral "8px";
      };
      "element selected" = {
        text-color = mkLiteral "@bg";
        background-color = mkLiteral "@fg";
      };
      element-icon = {
        size = mkLiteral "0.8em";
      };
      element-text = {
        text-color = mkLiteral "inherit";
      };
    };
  };
}
