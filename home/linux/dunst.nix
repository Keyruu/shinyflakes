{ ... }:
{
  services.dunst = {
    enable = true;
    settings = {
      global = {
        width = "250";
        height = "(75,150)";
        origin = "top-right";
        offset = "(30, 30)";
        alignment = "center";
        notification_limit = 20;
        progress_bar_height = 10;
        progress_bar_min_width = 150;
        progress_bar_max_width = 250;
        progress_bar_corner_radius = 5;
        icon_corner_radius = 5;
        corner_radius = 5;
        frame_width = 0;
        gap_size = 1;
        format = "<b>%s</b>\n%b";
        enable_recursive_icon_lookup = true;
        min_icon_size = 32;
        max_icon_size = 64;
      };

      urgency_low = {
        # background = "#16161e";
        # foreground = "#c0caf5";
        # frame_color = "#c0caf5";
      };

      urgency_normal = {
        # background = "#1a1b26";
        # foreground = "#c0caf5";
        # frame_color = "#c0caf5";
      };

      urgency_critical = {
        # background = "#292e42";
        # foreground = "#db4b4b";
        # frame_color = "#db4b4b";
      };
    };
  };
}
