{ den, ... }:
{
  den.aspects.prime.nixos =
    { config, pkgs, ... }:
    {
      sops = {
        secrets = {
          cloudflare = { };
          resticServerPassword = { };
        };
        templates."resticRepo".content =
          "rest:http://lucas:${config.sops.placeholder.resticServerPassword}@${den.people.lucas.devices.mentat.ip}:8004/restic";
      };

      networking = {
        nftables.enable = true;

        hosts."100.67.0.2" = [
          "cache.keyruu.de"
          "git.lab.keyruu.de"
        ];

        interfaces.eth0.ipv6.addresses = [
          {
            address = "2a01:4f8:1c1c:f355::1";
            prefixLength = 64;
          }
        ];
        defaultGateway6 = {
          address = "fe80::1";
          interface = "eth0";
        };
      };

      services = {
        monitoring = {
          metrics = {
            enable = true;
            interface = config.services.mesh.interface;
          };
          logs = {
            enable = true;
            instance = "100.67.0.1";
            lokiAddress = "http://${den.people.lucas.devices.mentat.ip}:3030";
          };
        };
        restic.defaults = {
          repoFile = config.sops.templates."resticRepo".path;
          # prevent lock collisions with mentat
          hour = 3;
        };
      };

      environment.systemPackages = with pkgs; [
        vim
        wget
        busybox
        ethtool
        dsnet
      ];

      nixpkgs.hostPlatform = "x86_64-linux";
    };
}
