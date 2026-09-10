{ den, ... }: {
  den.aspects.workstation.wm = {
    includes = with den.aspects.workstation.wm; [
      fonts
      graphical
      gtk
      qt
      # idle
      kanshi
      # lock
      niri
      session
    ];
  };
}
