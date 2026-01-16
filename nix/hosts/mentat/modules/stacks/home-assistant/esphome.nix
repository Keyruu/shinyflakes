{ config, pkgs, ... }:
let
  stackPath = "/etc/stacks/esphome/config";
  my = config.services.my.esphome;
in
{
  systemd.tmpfiles.rules = [
    "d ${stackPath} 0755 root root"
  ];

  services.my.esphome = {
    port = 6052;
    domain = "esphome.port.peeraten.net";
    proxy = {
      enable = true;
      cert.host = "port.peeraten.net";
    };
  };

  virtualisation.quadlet.containers.esphome = {
    containerConfig = {
      image = "ghcr.io/esphome/esphome:2025.12.6";
      environments = {
        TZ = "Europe/Berlin";
      };
      exposePorts = [
        "6052"
      ];
      addCapabilities = [
        "CAP_NET_RAW"
      ];
      volumes = [
        "${stackPath}:/config"
      ];
      networks = [
        "host"
      ];
    };
    serviceConfig = {
      Restart = "always";
    };
  };

  services.restic.backupsWithDefaults = {
    esphome = {
      backupPrepareCommand = "${pkgs.systemd}/bin/systemctl stop esphome";
      paths = [
        stackPath
      ];
      backupCleanupCommand = "${pkgs.systemd}/bin/systemctl start esphome";
    };
  };
}
