{
  den,
  inputs,
  ...
}:
{
  # Lucas laptop — Lenovo ThinkPad X1 Yoga Gen 7.
  # Second den-native host. Mesh client, fprintd-tod, lanzaboote secure-boot.
  den.hosts.x86_64-linux.thopter.users.lucas = { };

  den.aspects.thopter = {
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
      den.aspects.workstation.blueman
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
      den.aspects.workstation.fprintd

      # Mesh client (connects to mentat/prime via wireguard).
      # den.aspects.options.mesh
      # den.aspects.workstation.mesh-client
    ];

    nixos = { pkgs, ... }: {
      imports = [
        inputs.nixos-hardware.nixosModules.lenovo-thinkpad-x1-yoga-7th-gen
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

      # Mesh client config. IP pulled from blueprint's mesh.people.lucas.devices.thopter
      # until that data is migrated to a den aspect.
      # services.mesh = {
      #   ip = "100.67.0.4";
      #   client = {
      #     enable = true;
      #     autostart = false;
      #     keyName = "thopterMeshKey";
      #     allowedIPs = [
      #       "192.168.100.0/24"
      #     ];
      #     ws = {
      #       enable = true;
      #       defaultInterface = "wlp0s20f3";
      #     };
      #   };
      # };

      # X1 Yoga Gen 7 has a Goodix fingerprint reader — needs the TOD driver.
      # fprintd-tod package is selected automatically when tod.enable is set.
      services.fprintd = {
        package = pkgs.fprintd;
        tod = {
          enable = true;
          driver = pkgs.libfprint-2-tod1-goodix;
        };
      };

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
