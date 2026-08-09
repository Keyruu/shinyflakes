{
  den,
  inputs,
  lib,
  ...
}:
{
  # Lucas laptop. First den-native host, no blueprint equivalent.
  den.hosts.x86_64-linux.carryall.users.lucas = { };

  den.aspects.carryall = {
    includes = [
      # Core (every host)
      den.aspects.core.common
      den.aspects.core.secrets
      den.aspects.core.nixConfig
      den.aspects.core.locale
      den.aspects.core.nice
      den.aspects.core.podman
      den.aspects.core.gc
      den.aspects.core.hardening

      # Workstation — nixos-only aspects (host scope)
      den.aspects.workstation.laptop
      den.aspects.workstation.wayland
      den.aspects.workstation.bluetooth
      den.aspects.workstation.fonts
      den.aspects.workstation.networking
      den.aspects.workstation.sound
      den.aspects.workstation.gaming
      den.aspects.workstation.onepassword
      den.aspects.workstation.printing
      den.aspects.workstation.secure-boot
      den.aspects.workstation.plymouth
      den.aspects.workstation.systemd-boot
      den.aspects.workstation.kanata
      den.aspects.workstation.build-machines
      den.aspects.workstation.wireguard
      den.aspects.workstation.gotify-desktop
      den.aspects.workstation.appimage
      den.aspects.workstation.flatpak
      den.aspects.workstation.graphical
      den.aspects.workstation.udev

      # Mesh client (connects to mentat/prime via wireguard).
      # Mesh publicKey / IP for carryall not yet set — add when first needed.
      den.aspects.server.mesh-client
    ];

    nixos = {
      imports = [
        inputs.nixos-hardware.nixosModules.lenovo-thinkpad-t14s
        inputs.nixos-hardware.nixosModules.common-cpu-intel
        inputs.nixos-hardware.nixosModules.common-gpu-intel
      ];

      nixpkgs.hostPlatform = "x86_64-linux";

      networking.nftables.enable = true;

      services.libinput.enable = true;

      # Host-level extras on top of den.batteries.define-user (which provisions
      # the OS user + home dir). wheel/networkmanager added by primary-user.
      users.users.lucas.extraGroups = [
        "networkmanager"
        "ydotool"
        "docker"
        "disk"
      ];

      documentation = {
        enable = true;
        doc.enable = false;
        man.enable = true;
        dev.enable = false;
        info.enable = false;
        nixos.enable = false;
      };
    };
  };
}
