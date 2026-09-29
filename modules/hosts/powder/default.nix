{
  den,
  inputs,
  ...
}:
{
  den.hosts.x86_64-linux.powder = {
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
        work = "-411,-1543";
      };
    };
  };

  den.aspects.powder = {
    includes = [
      den.aspects.workstation.default
      den.aspects.workstation.laptop
      den.aspects.workstation.secure-boot
      den.aspects.workstation.fprintd
    ];

    nixos = { pkgs, lib, ... }: {
      imports = [
        ./_disk.nix
        # inputs.nixos-hardware.nixosModules.lenovo-thinkpad-t14s
      ];

      nixpkgs.hostPlatform = "x86_64-linux";

      # services.mesh = {
      #   ip = den.people.lucas.devices.powder.ip;
      #   client = {
      #     enable = true;
      #     keyName = "powderMeshKey";
      #     autostart = false;
      #     allowedIPs = [
      #       "192.168.100.0/24"
      #     ];
      #     ws = {
      #       enable = true;
      #       # defaultInterface = "wlp0s20f3";
      #     };
      #   };
      # };

      networking.nftables.enable = true;

      services.libinput.enable = true;

      # Workstation packages migrated from blueprint's workstation.nix + wayland.nix
      # (those nixos modules aren't migrated to den yet — see phase 3 cleanup).
      environment.systemPackages = with pkgs; [
        distrobox
        nautilus
      ];
      virtualisation.podman.dockerCompat = true;

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
