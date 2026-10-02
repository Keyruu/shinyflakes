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
      den.aspects.workstation.laptop
      den.aspects.workstation.secure-boot
      # den.aspects.workstation.fprintd
    ];

    nixos =
      {
        pkgs,
        lib,
        ...
      }:
      {
        imports = [
          ./_disk.nix
          ./_aikido.nix
        ];

        nixpkgs.hostPlatform = "x86_64-linux";

        hardware.facter.reportPath = ./facter.json;

        networking.hostName = lib.mkForce "lucas-rott-linux";

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

        # Node ships its own CA bundle and ignores the system store, so Aikido's
        # MITM CA (pinned in _aikido.nix) would be rejected otherwise.
        environment.variables.NODE_EXTRA_CA_CERTS = "/etc/ssl/certs/ca-certificates.crt";

        networking.useDHCP = lib.mkForce false;
        networking.interfaces.wlp0s20f3.useDHCP = lib.mkForce false;

        services.libinput.enable = true;
        services.tailscale.enable = true;

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
    homeManager = { ... }: {
      services.tailscale-systray.enable = true;
    };
  };
}
