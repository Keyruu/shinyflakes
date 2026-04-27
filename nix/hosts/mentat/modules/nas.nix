{
  config,
  perSystem,
  pkgs,
  ...
}:
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
      requestEncryptionCredentials = false;
    };
  };

  networking.hostId = "7dddaca4";

  environment.systemPackages = [ perSystem.self.zfs-unlock ];

  systemd.targets.zfs-encrypted = {
    description = "ZFS Encrypted Datasets Unlocked";
    after = [ "zfs-encrypted-check.service" ];
    requires = [ "zfs-encrypted-check.service" ];
  };

  systemd.services.zfs-encrypted-check = {
    description = "Check ZFS Encrypted Datasets Are Unlocked";
    after = [ "zfs.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = "${pkgs.bash}/bin/bash -c '${pkgs.zfs}/bin/zfs get -H -o value keystatus main/encrypted | grep -q available'";
    };
  };

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
      image = "ghcr.io/analogj/scrutiny:v0.9.1-omnibus";
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
