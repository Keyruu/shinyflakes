{ config, pkgs, ... }:
let
  my = config.services.my.jellyfin;
  stackPath = "/etc/stacks/jellyfin";
in
{
  systemd.tmpfiles.rules = [
    "d ${stackPath}/config 0770 root root"
    "d ${stackPath}/cache 0770 root root"
  ];

  services.my.jellyfin = {
    port = 8096;
    domain = "jellyfin.lab.keyruu.de";
    proxy.enable = true;
  };

  virtualisation.quadlet.containers.jellyfin = {
    containerConfig = {
      image = "ghcr.io/jellyfin/jellyfin:10.11.5";
      environments = {
      };
      volumes = [
        "${stackPath}/config:/config"
        "${stackPath}/cache:/cache"
        "/main/media:/media"
      ];
      publishPorts = [
        "127.0.0.1:${toString my.port}:${toString my.port}"
        "${config.services.mesh.ip}:${toString my.port}:${toString my.port}"
      ];
    };
    serviceConfig = {
      Restart = "always";
    };
  };

  services.restic.backupsWithDefaults = {
    jellyfin = {
      backupPrepareCommand = "${pkgs.systemd}/bin/systemctl stop jellyfin";
      paths = [
        stackPath
      ];
      backupCleanupCommand = "${pkgs.systemd}/bin/systemctl start jellyfin";
    };
  };
}
