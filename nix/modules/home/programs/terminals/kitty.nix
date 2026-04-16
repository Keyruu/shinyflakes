{ pkgs, ... }:
{
  programs.kitty = {
    enable = true;

    shellIntegration.enableZshIntegration = true;

    themeFile = "Dracula";

    settings = {
      window_margin_width = "10 10";
      hide_window_decorations = "titlebar-only";
      tab_bar_style = "powerline";
      background = "#100F0F";
      background_opacity = "0.7";
      enable_audio_bell = "false";
      visual_bell_duration = "0.2";
      visual_bell_color = "#003753";
      scrollback_lines = "10000";
    };
  };
}
