{
  den,
  inputs,
  ...
}:
{
  den.hosts.x86_64-linux.crystal = {
    users.lucas = { };

    # Kanshi profiles auto-generated from this config + options.monitors.
    # Work monitors (the docks) are primary; the laptop screen is the
    # secondary — handle social while docked, solo when undocked.
    displays = {
      primary = [
        "home"
        "work"
      ];
      secondaries = [ "laptop" ];
      positions = {
        laptop = "0,0";
        home = "-320,-1440";
        work = "-411,-1544";
      };
    };
  };

  den.aspects.powder = {
    includes = [
      den.aspects.workstation.laptop
      # den.aspects.workstation.secure-boot
      den.aspects.workstation.fprintd
    ];

    nixos =
      {
        lib,
        ...
      }:
      {
        imports = [
          ./_disk.nix
          ./_aikido.nix
          ./_firefox-policies.nix
        ];

        nixpkgs.hostPlatform = "x86_64-linux";

        hardware.facter.reportPath = ./facter.json;

        services.mesh = {
          ip = den.people.lucas.devices.powder.ip;
          client = {
            enable = true;
            keyName = "crystalMeshKey";
            autostart = true;
            allowedIPs = [
              "192.168.100.0/24"
            ];
            ws = {
              enable = true;
              defaultInterface = "wlp0s20f3";
            };
          };
        };

        networking.nftables.enable = true;

        networking.useDHCP = lib.mkForce false;
        networking.interfaces.wlp0s20f3.useDHCP = lib.mkForce false;

        services.libinput.enable = true;

        # Host-level extras on top of den.batteries.define-user (which provisions
        # the OS user + home dir). wheel/networkmanager added by primary-user.
        users.users.lucas.extraGroups = [
          "networkmanager"
          "ydotool"
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
