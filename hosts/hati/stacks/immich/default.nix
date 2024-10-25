{
  config,
  pkgs,
  ...
}: {
  environment.etc."stacks/immich/compose.yaml".source = ./compose.yaml;
  environment.etc."stacks/immich/hwaccel.yml".source = ./hwaccel.yml;
  environment.etc."stacks/immich/.env".text = ''
    UPLOAD_LOCATION=/mnt/immich
    IMMICH_VERSION=v1.112.1
    DB_PASSWORD=postgres

    DB_HOSTNAME=immich_postgres
    DB_USERNAME=postgres
    DB_DATABASE_NAME=immich

    REDIS_HOSTNAME=immich_redis
  '';

  fileSystems."/mnt/immich" = {
    device = "192.168.100.16:/mnt/main/immich";
    fsType = "nfs";
  };

  systemd.services.immich = {
    wantedBy = ["multi-user.target"];
    after = ["docker.service" "docker.socket"];
    path = [pkgs.docker];
    script = ''
      docker compose -f /etc/stacks/immich/compose.yaml up
    '';
    restartTriggers = [
      config.environment.etc."stacks/immich/compose.yaml".source
      config.environment.etc."stacks/immich/hwaccel.yml".source
      config.environment.etc."stacks/immich/.env".source
    ];
  };

  security.acme = {
    certs."immich.keyruu.de" = {
      domain = "immich.keyruu.de";
      dnsProvider = "cloudflare";
      dnsPropagationCheck = true;
      environmentFile = config.sops.secrets.cloudflare.path;
    };
  };

  services.nginx.virtualHosts."immich.keyruu.de" = {
    useACMEHost = "immich.keyruu.de";
    forceSSL = true;

    locations."/" = {
      proxyPass = "http://127.0.0.1:2283";
      proxyWebsockets = true;
    };
  };
}
