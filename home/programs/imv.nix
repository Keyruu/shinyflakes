{
  programs.imv = {
    enable = true;
    settings = {
      options = {
        overlay_font = "monospace:10";
        overlay = true;
        overlay_position_bottom = true;
      };
      binds = {
        "w" = ''exec setbg "$imv_current_file"'';
        "<comma>" = "prev_frame";
      };
    };
  };
}
