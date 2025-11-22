{
  inputs,
  config,
  perSystem,
  ...
}:
{
  systemd.tmpfiles.rules = [
    "d /etc/stacks/copyparty 0770 root root"
  ];

  imports = [
    inputs.copyparty.nixosModules.default
  ];

  sops.secrets.copypartyPassword = { };

  networking.firewall.interfaces = {
    "eth0".allowedTCPPorts = [ config.services.copyparty.settings.p ];
    "tailscale0".allowedTCPPorts = [ config.services.copyparty.settings.p ];
  };

  services.copyparty = {
    enable = true;
    package = perSystem.copyparty.default;
    user = "root";
    group = "root";

    settings = {
      i = "0.0.0.0";
      p = 3210;
      shr = "/shared";
      shr-adm = "root";
      ipr = "192.168.100.0/24,100.64.0.0/16=root";
      rproxy = -1;
      xff-src = "lan,100.64.0.0/16";
      # xff-hdr = "cf-connecting-ip";
      hist = "/etc/stacks/copyparty";
    };

    accounts = {
      "root" = {
        passwordFile = config.sops.secrets.copypartyPassword.path;
      };
    };

    volumes = {
      "/" = {
        path = "/main";
        access = {
          rw = [ "root" ];
        };
      };
      "/public" = {
        path = "/main/dav/public";
        access = {
          r = "*";
          rw = [ "root" ];
        };
      };
    };

    openFilesLimit = 8192;
  };

  security.acme.certs."files.keyruu.de" = {
    dnsProvider = "cloudflare";
    dnsPropagationCheck = true;
    environmentFile = config.sops.secrets.cloudflare.path;
  };

  services.nginx.virtualHosts = {
    "files.lab.keyruu.de" = {
      useACMEHost = "lab.keyruu.de";
      forceSSL = true;

      locations."/" = {
        proxyPass = "http://127.0.0.1:3210";
        proxyWebsockets = true;
      };
    };

    "files.keyruu.de" = {
      useACMEHost = "files.keyruu.de";
      forceSSL = true;

      inherit (config.services.nginx.virtualHosts."files.lab.keyruu.de") locations;
    };
  };
}
