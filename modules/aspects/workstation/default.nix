{ den, ... }: {
  den.aspects.workstation = {
    includes = with den.aspects.workstation; [
      appimage
      bluetooth
      build-machines
      flatpak
      gotify-desktop
      kanata
      mesh-client
      networking
      onepassword
      plymouth
      printing
      sound
      systemd-boot
      udev
      wireguard
      wm
    ];
  };
}
