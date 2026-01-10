{ config, ... }:
let
  stackPath = "/etc/stacks/garage";
in
{
  systemd.tmpfiles.rules = [
    "d ${stackPath}/meta 0755 root root"
  ];

  sops.secrets = {
    garageAdminToken = { };
    garageMetricsToken = { };
    garageRpcToken = { };
  };

  networking.firewall.interfaces = {
    eth0.allowedTCPPorts = [
      3900
      3902
    ];
    "${config.services.mesh.interface}".allowedTCPPorts = [
      3900
      3902
    ];
  };

  sops.templates."garage.toml" = {
    restartUnits = [ "garage.service" ];
    content = ''
      metadata_dir = "/var/lib/garage/meta"
      data_dir = "/var/lib/garage/data"

      db_engine = "sqlite"

      replication_factor = 1

      rpc_bind_addr = "[::]:3901"
      rpc_public_addr = "[::]:3901"
      rpc_secret = "${config.sops.placeholder.garageRpcToken}"

      [s3_api]
      s3_region = "garage"
      api_bind_addr = "[::]:3900"
      root_domain = ".s3.keyruu.de"

      [s3_web]
      bind_addr = "[::]:3902"
      root_domain = ".garage.keyruu.de"

      [admin]
      api_bind_addr = "[::]:3903"
      metrics_token = "${config.sops.placeholder.garageMetricsToken}"
      admin_token = "${config.sops.placeholder.garageAdminToken}"
    '';
  };

  virtualisation.quadlet.containers.garage = {
    containerConfig = {
      image = "docker.io/dxflrs/garage:v2.1.0";
      publishPorts = [
        "127.0.0.1:3900:3900"
        "127.0.0.1:3902:3902"
        "${config.services.mesh.ip}:3900:3900"
        "${config.services.mesh.ip}:3902:3902"
        "3901:3901"
        "127.0.0.1:3903:3903"
      ];
      volumes = [
        "${config.sops.templates."garage.toml".path}:/etc/garage.toml:ro"
        "${stackPath}/meta:/var/lib/garage/meta"
        "/main/data/s3:/var/lib/garage/data"
      ];
      labels = [
        "wud.tag.include=^v\\d+\\.\\d+\\.\\d+$"
      ];
    };
    serviceConfig = {
      Restart = "always";
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
