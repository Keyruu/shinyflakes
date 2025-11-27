{ config, ... }:
let
  karaokeDomain = "29112025karaoke.keyruu.de";
  stackPath = "/etc/stacks/pikaraoke";
in
{
  systemd.tmpfiles.rules = [
    "d ${stackPath}/songs 0750 root root"
  ];

  sops.secrets.karaokeAdminPassword = { };
  sops.templates."pikaraoke.env" = {
    restartUnits = [
      "pikaraoke.service"
    ];
    content = ''
      KARAOKE_ADMIN_PASSWORD=${config.sops.placeholder.karaokeAdminPassword}
    '';
  };

  virtualisation.quadlet.containers.pikaraoke = {
    containerConfig = {
      image = "docker.io/vicwomg/pikaraoke:latest";
      publishPorts = [ "127.0.0.1:5555:5555" ];
      exec = [
        "-u"
        "https://${karaokeDomain}"
        "--admin-password"
        "rasenschach"
      ];
      volumes = [
        "${stackPath}/songs:/app/pikaraoke-songs"
      ];
      environmentFiles = [ config.sops.templates."pikaraoke.env".path ];
    };
  };

  security.acme = {
    certs = {
      "keyruu.de" = {
        extraDomainNames = [ "*.keyruu.de" ];
        dnsProvider = "cloudflare";
        dnsPropagationCheck = true;
        environmentFile = config.sops.secrets.cloudflare.path;
      };
    };
  };

  services.nginx.virtualHosts."${karaokeDomain}" = {
    useACMEHost = "keyruu.de";
    forceSSL = true;

    locations."/" = {
      proxyPass = "http://127.0.0.1:5555";
      proxyWebsockets = true;
    };
  };
}
