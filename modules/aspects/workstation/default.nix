{ den, ... }: {
  den.aspects.workstation.default = {
    includes = with den.aspects.workstation; [
      appimage
      bluetooth
      build-machines
      gotify-desktop
      kanata
      mesh-client
      networking
      onepassword
      plymouth
      printing
      secrets
      sound
      systemd-boot
      udev
      wireguard
      wm
    ];

    # Zen kernel for all workstations (carryall, muadib, thopter).
    # Blueprint-side: `nix/modules/nixos/laptop.nix` set it per-laptop,
    # `muadib/configuration.nix` set it directly. Centralizing here.
    nixos = { pkgs, ... }: {
      boot.kernelPackages = pkgs.linuxPackages_zen;
    };
  };
}
