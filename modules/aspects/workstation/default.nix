{ den, ... }: {
  den.aspects.workstation.default = {
    includes = with den.aspects.workstation; [
      appimage
      bluetooth
      build-machines
      disk
      gotify-desktop
      kanata
      mesh-client
      networking
      onepassword
      plymouth
      printing
      secrets
      ssh
      sound
      sunshine
      systemd-boot
      udev
      wireguard
      wm
    ];

    nixos = { pkgs, ... }: {
      boot.kernelPackages = pkgs.linuxPackages_zen;
    };
  };
}
