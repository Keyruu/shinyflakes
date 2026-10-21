{ den, inputs, ... }: {
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
      sound
      sunshine
      systemd-boot
      udev
      wireguard
      wm
    ];

    nixos = { pkgs, ... }: {
      # FIXME: drop pin when linux_zen includes the 7.2.12 SoundWire fix.
      # https://github.com/NixOS/nixpkgs/pull/574702
      boot.kernelPackages = pkgs.linuxPackagesFor (
        inputs.nixpkgs-multiverse.multiverse.${pkgs.stdenv.hostPlatform.system}.versions.linux_zen."7.2.9"
      );
    };
  };
}
