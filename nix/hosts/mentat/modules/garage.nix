{ config, pkgs, ... }:
{
  sops.secrets = {
    garageAdminToken = {
      group = "garage";
      mode = "440";
    };
    garageMetricsToken = {
      group = "garage";
      mode = "440";
    };
    garageRpcToken = {
      group = "garage";
      mode = "440";
    };
  };

  networking.firewall.interfaces = {
    eth0.allowedTCPPorts = [ 3900 ];
    tailscale0.allowedTCPPorts = [ 3902 ];
  };

  services.garage = {
    enable = true;
    package = pkgs.garage_2;
    settings = {
      data_dir = [ "/main/data/s3" ];
      rpc_bind_addr = "[::]:3901";
      rpc_secret_file = config.sops.secrets.garageRpcToken.path;

      s3_api = {
        api_bind_addr = "[::]:3900";
        s3_region = "garage";
        root_domain = ".s3.keyruu.de";
      };

      s3_web = {
        bind_addr = "[::]:3902";
        root_domain = ".garage.keyruu.de";
      };
      admin = {
        api_bind_addr = "0.0.0.0:3903";
        metrics_token_file = config.sops.secrets.garageMetricsToken.path;
        admin_token_file = config.sops.secrets.garageAdminToken.path;
      };
    };
  };

  security.acme.certs = {
    "s3.keyruu.de" = {
      dnsProvider = "cloudflare";
      dnsPropagationCheck = true;
      environmentFile = config.sops.secrets.cloudflare.path;
    };
    "garage.keyruu.de" = {
      dnsProvider = "cloudflare";
      dnsPropagationCheck = true;
      environmentFile = config.sops.secrets.cloudflare.path;
    };
  };

  services.nginx.virtualHosts = {
    "s3.keyruu.de" = {
      useACMEHost = "s3.keyruu.de";
      forceSSL = true;

      locations."/" = {
        proxyPass = "http://127.0.0.1:3900";
        proxyWebsockets = true;
      };
    };

    "garage.keyruu.de" = {
      useACMEHost = "garage.keyruu.de";
      forceSSL = true;

      locations."/" = {
        proxyPass = "http://127.0.0.1:3902";
        proxyWebsockets = true;
      };
    };
  };
}
