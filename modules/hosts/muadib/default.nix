{
  den,
  ...
}:
{
  # Lucas desktop workstation. AMD, linuxPackages_zen, gaming.
  # Second den-native workstation after carryall.
  den.hosts.x86_64-linux.muadib.users.lucas = { };

  den.aspects.muadib = {
    includes = [
      den.aspects.workstation.gaming
    ];

    nixos = { pkgs, host, ... }: {
      nixpkgs.hostPlatform = "x86_64-linux";

      networking.nftables.enable = true;

      services.libinput.enable = true;

      # Host-level extras on top of den.batteries.define-user.
      users.users.lucas.extraGroups = [
        "networkmanager"
        "ydotool"
        "docker"
        "disk"
      ];

      services.mesh = {
        client = {
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
