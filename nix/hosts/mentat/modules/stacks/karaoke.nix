{ config, flake, ... }:
let
  karaokeDomain = "29042026.karaoke.keyruu.de";
  stackPath = "/etc/stacks/pikaraoke";
  inherit (config.virtualisation.quadlet) containers;
  inherit (flake.lib) quadlet;
in
{
  systemd.tmpfiles.rules = [
    "d ${stackPath}/songs 0750 root root"
  ];

  sops.secrets = {
    karaokeAdminPassword = { };
    karaokeCookies = { };
  };
  sops.templates."pikaraoke.env" = {
    restartUnits = [
      (quadlet.service containers.pikaraoke)
    ];
    content = ''
      KARAOKE_ADMIN_PASSWORD=${config.sops.placeholder.karaokeAdminPassword}
    '';
  };

  virtualisation.quadlet.containers.pikaraoke = {
    containerConfig = {
      image = "docker.io/vicwomg/pikaraoke:1.19.0";
      publishPorts = [ "${config.services.mesh.ip}:5555:5555" ];
      entrypoint = [
        "/bin/sh"
        "-c"
        ''
          exec pikaraoke \
            -u "https://${karaokeDomain}" \
            --admin-password "$KARAOKE_ADMIN_PASSWORD" \
            --limit-user-songs-by 3 \
            --ytdl-args "--cookies /app/cookies.txt"
        ''
      ];
      volumes = [
        "${stackPath}/songs:/app/pikaraoke-songs"
        "${config.sops.secrets.karaokeCookies.path}:/app/cookies.txt:ro"
      ];
      environmentFiles = [ config.sops.templates."pikaraoke.env".path ];
    };
  };

  # security.acme = {
  #   certs = {
  #     "keyruu.de" = {
  #       extraDomainNames = [ "*.keyruu.de" ];
  #       dnsProvider = "cloudflare";
  #       dnsPropagationCheck = true;
  #       environmentFile = config.sops.secrets.cloudflare.path;
  #     };
  #   };
  # };

  # services.nginx.virtualHosts."${karaokeDomain}" = {
  #   useACMEHost = "keyruu.de";
  #   forceSSL = true;

  #   locations."/" = {
  #     proxyPass = "http://127.0.0.1:5555";
  #     proxyWebsockets = true;
  #   };
  # };
}
