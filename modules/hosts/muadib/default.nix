{
  den,
  config,
  ...
}:
{
  # Lucas desktop workstation. AMD, linuxPackages_zen, gaming.
  # Second den-native workstation after carryall.
  den.hosts.x86_64-linux.muadib = {
    users.lucas = { };

    # Mesh identity on host entity (single source of truth for registry
    # hostIp + mesh peer list).
    mesh = {
      ip = config.den.people.lucas.devices.muadib.ip;
      publicKey = "dBpryxEEqSYKnaMjdStm/cqf7R3QtlWNZDQnr4dKek4=";
    };
  };

  den.aspects.muadib = {
    # Mesh client identity (this host as a wireguard peer). The
    # mesh-device quirk flows to the Hetzner mesh server via
    # policies/mesh.nix's collection policy.
    mesh-device =
      { host, ... }:
      host.mesh
      // {
        name = "muadib";
      };

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
      den.aspects.workstation.fprintd

      # Mesh client — connects to the Hetzner mesh server (see
      # policies/mesh.nix for the synthetic server entry).
      den.aspects.workstation.mesh.client
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

      # Mesh client config. IP from people.nix (single source of truth).
      # SOPS secret `muadibMeshKey` must exist in nix/secrets.yaml
      # holding the matching wg private key.
      services.mesh = {
        ip = config.den.hosts.x86_64-linux.muadib.mesh.ip;
        subnet = "100.67.0.0/24";
        client = {
          keyName = "muadibMeshKey";
          autostart = true;
          ws = {
            enable = true;
            defaultInterface = "enp42s0";
          };
        };
      };

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
