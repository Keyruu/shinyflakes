{ den, ... }: {
  den.aspects.tools = {
    includes = with den.aspects.tools; [
      "1password"
      calendar
      clipse
      colorpicker
      element
      git
      k9s
      kbptr
      lazygit
      mail
      mpv
      nh
      nix-index-database
      noctalia
      repos
      satty
      screenshot
      system
      television
      vicinae
      which-key
      yazi
    ];
  };
}
