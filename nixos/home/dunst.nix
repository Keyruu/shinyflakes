{
  # notification daemon
  services.dunst = {
    enable = true;
    settings = {
      global = {
        width = "(0, 500)";
        offset = "8x48";
        font = "monospace 11";
        gap_size = 8;
        icon_position = "right";
        frame_width = 0;
        foreground = "#bdbdbd";
        background = "#080808";
        max_icon_size = 64;
      };
      urgency_low = {
        timeout = 5;
      };
      urgency_normal = {
        timeout = 10;
      };
      urgency_critical = {
        background = "#ff6e6e";
        foreground = "#080808";
        timeout = 15;
      };
    };
  };
}
