{
  den,
  inputs,
  ...
}:
{
  # Lucas laptop — Lenovo ThinkPad X1 Yoga Gen 7.
  den.hosts.x86_64-linux.thopter = {
    users.lucas = { };

    displays = {
      primary = [ "home" "work" ];
      secondaries = [ "laptop" ];
      positions = {
        laptop = "0,0";
        home = "-320,-1440";
        work = "-411,-1543";
      };
    };
  };

  den.aspects.thopter = {
    includes = [
      den.aspects.workstation.laptop
      den.aspects.workstation.secure-boot
      den.aspects.workstation.fprintd
    ];

    nixos = { pkgs, host, ... }: {
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
        "ydotool"
        "docker"
        "disk"
      ];

      services.mesh = {
        client = {
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
