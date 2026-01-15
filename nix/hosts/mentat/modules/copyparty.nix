{
  inputs,
  config,
  perSystem,
  ...
}:
let
  my = config.services.my.copyparty;
in
{
  systemd.tmpfiles.rules = [
    "d /etc/stacks/copyparty 0770 root root"
  ];

  imports = [
    inputs.copyparty.nixosModules.default
  ];

  sops.secrets.copypartyPassword = { };

  networking.firewall.interfaces = {
    "${config.services.mesh.interface}".allowedTCPPorts = [ config.services.copyparty.settings.p ];
  };

  services = {
    my.copyparty =
      let
        domain = "files.keyruu.de";
      in
      {
        enable = true;
        port = 3210;
        inherit domain;
        proxy = {
          enable = true;
          cert = {
            provided = false;
            host = domain;
          };
        };
      };

    copyparty = {
      enable = true;
      package = perSystem.copyparty.default;
      user = "root";
      group = "root";

      settings = {
        i = "0.0.0.0";
        p = my.port;
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
  };

  services.nginx.virtualHosts = {
    "files.lab.keyruu.de" = {
      useACMEHost = "lab.keyruu.de";
      forceSSL = true;
      inherit (config.services.nginx.virtualHosts."${my.domain}") locations;
    };
  };
}
