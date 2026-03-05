{ config, flake, ... }:
let
  karaokeDomain = "29112025karaoke.keyruu.de";
  stackPath = "/etc/stacks/pikaraoke";
  inherit (config.virtualisation.quadlet) containers;
  inherit (flake.lib) quadlet;
in
{
  systemd.tmpfiles.rules = [
    "d ${stackPath}/songs 0750 root root"
  ];

  sops.secrets.karaokeAdminPassword = { };
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
      image = "docker.io/vicwomg/pikaraoke:latest";
      publishPorts = [ "${config.services.mesh.ip}:5555:5555" ];
      exec = [
        "-u"
        "https://${karaokeDomain}"
        "--admin-password"
        "rasenschach"
        "--limit-user-songs-by"
        "3"
      ];
      volumes = [
        "${stackPath}/songs:/app/pikaraoke-songs"
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
