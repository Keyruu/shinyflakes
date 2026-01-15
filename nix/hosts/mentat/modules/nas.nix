{ config, pkgs, ... }:
let
  my = config.services.my.scrutiny;
in
{
  imports = [
    ./samba.nix
  ];

  boot = {
    supportedFilesystems = [ "zfs" ];
    zfs = {
      package = pkgs.zfs_unstable;
      forceImportRoot = false;
      extraPools = [ "main" ];
    };
  };

  networking.hostId = "7dddaca4";

  services = {
    zfs.autoScrub.enable = true;

    smartd = {
      enable = true;
    };

    my.scrutiny = {
      enable = true;
      port = 6333;
      domain = "scrutiny.lab.keyruu.de";
      proxy.enable = true;
    };
  };

  virtualisation.quadlet.containers.scrutiny = {
    containerConfig = {
      image = "ghcr.io/analogj/scrutiny:master-omnibus";
      addCapabilities = [
        "SYS_RAWIO"
        "SYS_ADMIN"
      ];
      devices = [
        "/dev/disk/by-id/ata-ST12000VN0007-2GS116_ZJV4GM17"
        "/dev/disk/by-id/ata-ST12000VN0007-2GS116_ZJV47ZND"
        "/dev/disk/by-id/ata-CT1000BX500SSD1_2436E98B10D6"
      ];
      publishPorts = [
        "127.0.0.1:${toString my.port}:8080"
        "127.0.0.1:6334:8086"
      ];
    };
    serviceConfig = {
      Restart = "always";
    };
  };

  systemd.services.beszel-agent.environment.EXTRA_FILESYSTEMS =
    "/dev/disk/by-id/ata-ST12000VN0007-2GS116_ZJV47ZND,/dev/disk/by-id/ata-ST12000VN0007-2GS116_ZJV4GM17";
}
