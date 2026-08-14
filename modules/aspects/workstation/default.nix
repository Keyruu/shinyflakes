{ den, ... }: {
  den.aspects.workstation = {
    includes = with den.aspects.workstation; [
      appimage
      bluetooth
      build-machines
      flatpak
      fprintd
      gaming
      gotify-desktop
      kanata
      laptop
      mesh
      networking
      onepassword
      plymouth
      printing
      secure-boot
      sound
      systemd-boot
      udev
      wireguard
      wm
    ];
  };
}
