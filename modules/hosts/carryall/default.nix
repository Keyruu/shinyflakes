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

      # Workstation — host-specific (shared concerns moved to users/lucas.nix)
      den.aspects.workstation.laptop
      den.aspects.workstation.secure-boot

      # Mesh client (connects to mentat/prime via wireguard).
      # Mesh publicKey / IP for carryall not yet set — add when first needed.
      # den.aspects.server.mesh-client
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
