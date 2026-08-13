{
  den,
  inputs,
  config,
  ...
}:
{
  # Lucas laptop — Lenovo ThinkPad X1 Yoga Gen 7.
  # Second den-native host. Mesh client, fprintd-tod, lanzaboote secure-boot.
  den.hosts.x86_64-linux.thopter = {
    users.lucas = { };

    # Mesh identity on host entity (single source of truth for registry
    # hostIp + mesh peer list). allowedIPs lets thopter route the LAN
    # through the mesh.
    mesh = {
      ip = config.den.people.lucas.devices.thopter.ip;
      publicKey = "PL5/3dK1BeIxoJufy51QHjMFQOq7SFR7WZ0sLmjqZW4=";
      allowedIPs = [ "192.168.100.0/24" ];
    };
  };

  den.aspects.thopter = {
    # Mesh client identity (this host as a wireguard peer). The
    # mesh-device quirk flows to the Hetzner mesh server via
    # policies/mesh.nix's collection policy.
    mesh-device = { host, ... }: host.mesh // { name = "thopter"; };

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

      # Workstation — host-specific (shared concerns moved to users/lucas.nix)
      den.aspects.workstation.laptop
      den.aspects.workstation.secure-boot
      den.aspects.workstation.fprintd

      # Mesh client — connects to the Hetzner mesh server (see
      # policies/mesh.nix for the synthetic server entry).
      den.aspects.workstation.mesh-client
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

      # Mesh client config. IP from people.nix (single source of truth).
      # SOPS secret `thopterMeshKey` must exist in nix/secrets.yaml
      # holding the matching wg private key.
      services.mesh = {
        ip = config.den.hosts.x86_64-linux.thopter.mesh.ip;
        subnet = "100.67.0.0/24";
        client = {
          keyName = "thopterMeshKey";
          autostart = false;
          ws = {
            enable = true;
            defaultInterface = "wlp0s20f3";
          };
        };
      };

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
