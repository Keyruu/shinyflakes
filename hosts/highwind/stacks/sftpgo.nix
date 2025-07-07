{ config, ... }:
let
  stackPath = "/etc/stacks/sftpgo";
in
{
  systemd.tmpfiles.rules = [
    "d ${stackPath}/config 0755 1000 1000"
  ];

  virtualisation.quadlet = {
    containers = {
      sftpgo = {
        containerConfig = {
          image = "drakkan/sftpgo:v2.6.6-alpine-slim";
          environments = {
            SFTPGO_WEBDAVD__BINDINGS__0__PORT = "8081";
            SFTPGO_WEBDAVD__BINDINGS__0__PREFIX = "/dav";
          };
          publishPorts = [
            "127.0.0.1:9433:8080" # Web
            "127.0.0.1:9434:8081" # WebDAV
          ];
          volumes = [
            "/main/dav:/srv/sftpgo"
            "${stackPath}/config:/var/lib/sftpgo"
          ];
          labels = [
            "wud.tag.include=^v\\d+\\.\\d+\\.\\d+-alpine-slim$"
          ];
        };
        serviceConfig = {
          Restart = "always";
        };
      };
    };
  };

  services.nginx.virtualHosts."files.lab.keyruu.de" = {
    useACMEHost = "lab.keyruu.de";
    forceSSL = true;
    locations = {
      "/" = {
        proxyPass = "http://127.0.0.1:9433";
        proxyWebsockets = true;
      };
      "/dav" = {
        proxyPass = "http://127.0.0.1:9434";
        proxyWebsockets = true;
      };
    };
  };
}
