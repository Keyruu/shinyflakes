{
  den,
  inputs,
  config,
  ...
}:
{
  # Lucas laptop. First den-native host, no blueprint equivalent.
  den.hosts.x86_64-linux.carryall.users.lucas = { };

  den.aspects.carryall =
    let
      mesh-ip = config.den.people.lucas.devices.carryall.ip;
    in
    {
      # Mesh client identity (this host as a wireguard peer). The
      # mesh-device quirk flows to the Hetzner mesh server via
      # policies/mesh.nix's collection policy.
      mesh-device = {
        name = "carryall";
        ip = mesh-ip;
        publicKey = "7Qn12iKEGxRNIEAOkoKQ2FUXKzvWWEP6ORJ3IHJ/sBI=";
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
        den.aspects.workstation.laptop
        den.aspects.workstation.secure-boot

        # Mesh client — connects to the Hetzner mesh server (see
        # policies/mesh.nix for the synthetic server entry).
        den.aspects.workstation.mesh-client
      ];

      nixos = { ... }: {
        imports = [
          inputs.nixos-hardware.nixosModules.lenovo-thinkpad-t14s
          inputs.nixos-hardware.nixosModules.common-cpu-intel
          inputs.nixos-hardware.nixosModules.common-gpu-intel
        ];

        nixpkgs.hostPlatform = "x86_64-linux";

        # Mesh client config (consumed by workstation.mesh-client aspect).
        # SOPS secret `carryallMeshKey` must exist in nix/secrets.yaml
        # holding the matching wg private key.
        services.mesh = {
          ip = mesh-ip;
          subnet = "100.67.0.0/24";
          client = {
            keyName = "carryallMeshKey";
            autostart = true;
            ws.enable = false;
          };
        };

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
