{
  den,
  inputs,
  ...
}:
{
  # Lucas laptop. First den-native host, no blueprint equivalent.
  den.hosts.x86_64-linux.carryall.users.lucas = { };

  den.aspects.carryall = {
    includes = [
      den.aspects.workstation.laptop
      den.aspects.workstation.secure-boot
    ];

    nixos = { ... }: {
      imports = [
        inputs.nixos-hardware.nixosModules.lenovo-thinkpad-t14s
        inputs.nixos-hardware.nixosModules.common-cpu-intel
        inputs.nixos-hardware.nixosModules.common-gpu-intel
      ];

      nixpkgs.hostPlatform = "x86_64-linux";

      services.mesh = {
        ip = den.people.lucas.carryall.ip;
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
