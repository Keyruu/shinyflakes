{ config, pkgs, ... }:
{
  programs.kitty = {
    enable = true;

    shellIntegration.enableZshIntegration = true;

    themeFile = "Dracula";

    settings = {
      window_margin_width = "10 10";
      hide_window_decorations = "titlebar-only";
      tab_bar_style = "powerline";
      background_blur = "1";
      background_opacity = "0.9";
      enable_audio_bell = "false";
      visual_bell_duration = "0.2";
      visual_bell_color = "#003753";
      font_family = config.user.font;
      font_size = "13";
      scrollback_lines = "10000";
    };

    keybindings = {
      "super+n" = "new_os_window";
    };

    # After theme so it overrides Dracula's #282a36 background
    extraConfig = ''
      background #100F0F
    '';
  };
}
