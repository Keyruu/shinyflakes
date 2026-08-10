{ den, ... }: {
  den.aspects.workstation.wm = {
    includes = with den.aspects.workstation.wm; [
      fonts
      graphical
      gtk
      idle
      kanshi
      lock
      niri
      session
    ];
  };
}
