{ config, ... }:
let
  karaokeDomain = "29112025.karaoke.keyruu.de";
in
{
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
      image = "docker.io/vicowomg/pikaraoke:latest";
      publishPorts = [ "127.0.0.1:5555:5555" ];
      exec = [
        "-u"
        "https://${karaokeDomain}"
        "--admin-password"
        "$KARAOKE_ADMIN_PASSWORD"
      ];
      environmentFiles = [ config.sops.templates."pikaraoke.env".path ];
    };
  };

  services.nginx.virtualHosts."${karaokeDomain}" = {
    enableACME = true;
    forceSSL = true;

    locations."/" = {
      proxyPass = "http://127.0.0.1:5555";
      proxyWebsockets = true;
    };
  };
}
