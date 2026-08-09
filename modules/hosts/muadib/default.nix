{
  den,
  inputs,
  ...
}:
{
  # Lucas desktop workstation. AMD, linuxPackages_zen, gaming.
  # Second den-native workstation after carryall.
  den.hosts.x86_64-linux.muadib.users.lucas = { };

  den.aspects.muadib = {
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

      # Workstation — nixos-only aspects
      den.aspects.workstation.wayland
      den.aspects.workstation.bluetooth
      den.aspects.workstation.blueman
      den.aspects.workstation.fonts
      den.aspects.workstation.networking
      den.aspects.workstation.sound
      den.aspects.workstation.gaming
      den.aspects.workstation.onepassword
      den.aspects.workstation.printing
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

      # Mesh options + client
      # den.aspects.options.mesh
      # den.aspects.server.mesh-client
    ];

    nixos = { pkgs, ... }: {
      nixpkgs.hostPlatform = "x86_64-linux";

      # Zen kernel — gaming-focused desktop
      boot.kernelPackages = pkgs.linuxPackages_zen;

      networking.nftables.enable = true;

      services.libinput.enable = true;

      # Host-level extras on top of den.batteries.define-user.
      users.users.lucas.extraGroups = [
        "networkmanager"
        "ydotool"
        "docker"
        "disk"
      ];

      # Mesh client config. IP from blueprint's mesh.people.lucas.devices.muadib.
      # services.mesh = {
      #   ip = "100.67.0.6";
      #   client = {
      #     enable = true;
      #     ws = {
      #       enable = true;
      #       defaultInterface = "enp42s0";
      #     };
      #     keyName = "muadibMeshKey";
      #   };
      # };

      # Custom firewall ports for game servers (hytale UDP range, etc).
      # mesh0 rules removed — mesh disabled.
      networking.firewall.interfaces = {
        enp42s0 = {
          allowedTCPPorts = [
            6767
            8080
          ];
          allowedUDPPorts = [ 2021 ];
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
