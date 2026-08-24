{ den, ... }: {
  den.aspects.tools.default = {
    includes = with den.aspects.tools; [
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
      syncthing
      system
      television
      vicinae
      which-key
      yazi
    ];
  };
}
