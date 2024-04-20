{...}: {
  programs.kitty = {
    enable = true;
    font = {
      name = "JetBrainsMono Nerd Font";
      size = 14;
    };

    shellIntegration.enableZshIntegration = true;

    settings = {
      window_margin_width = "10 10";
      hide_window_decorations = "titlebar-only";
      tab_bar_style = "powerline";
      background = "#011627";
      background_opacity = "0.7";
      enable_audio_bell = "false";
      visual_bell_duration = "0.2";
      visual_bell_color = "#003753";
    };
  };
}
