{ den, ... }: {
  den.aspects.tools.default = {
    includes = with den.aspects.tools; [
      calendar
      clipse
      colorpicker
      element
      file-explorer
      git
      k9s
      kbptr
      lazygit
      mail
      mpv
      nh
      nix-index-database
      # noctalia
      dms
      repos
      satty
      screenshot
      sofka
      sone
      syncthing
      television
      vicinae
      which-key
      yazi
    ];
  };
}
