{ config, ... }:
let
  inherit (config.virtualisation.quadlet) containers;
  mountPoint = "/main/media/nzbdav";
in
{
  sops.secrets.nzbdavWebdavPassword = { };

  # mount point must exist on host before rclone mounts there
  systemd.tmpfiles.rules = [
    "d ${mountPoint} 0755 root root -"
  ];

  # rclone remote "nzbdav" built from env vars; pass goes through SOPS template
  # so the obscured password never lands in the systemd unit or container env literal
  sops.templates."nzbdav-rclone.env" = {
    restartUnits = [ "nzbdav-rclone.service" ];
    content = ''
      RCLONE_CONFIG_NZBDAV_TYPE=webdav
      RCLONE_CONFIG_NZBDAV_URL=http://localhost:3000/
      RCLONE_CONFIG_NZBDAV_VENDOR=other
      RCLONE_CONFIG_NZBDAV_USER=admin
      RCLONE_CONFIG_NZBDAV_PASS=${config.sops.placeholder.nzbdavWebdavPassword}
    '';
  };

  # FUSE sidecar — NOT in the stack module. Needs SYS_ADMIN + /dev/fuse +
  # apparmor unconfined + bind mount with shared propagation, which the stack
  # module doesn't expose. Lives in gluetun's netns so localhost:3000 reaches nzbdav.
  virtualisation.quadlet.containers.nzbdav-rclone = {
    containerConfig = {
      image = "docker.io/rclone/rclone:1.75.0";
      addCapabilities = [ "SYS_ADMIN" ];
      devices = [ "/dev/fuse" ];
      appArmor = "unconfined";
      noNewPrivileges = false;
      networks = [ "media-gluetun.container" ];
      # :rshared so the FUSE mount at ${mountPoint} inside this container
      # propagates back to the host — radarr/sonarr/jellyfin later bind-mount
      # /main/media and see the FUSE contents at the same absolute path
      volumes = [
        "/main:/main:rshared"
        "/etc/localtime:/etc/localtime:ro"
      ];
      environmentFiles = [ config.sops.templates."nzbdav-rclone.env".path ];
      exec =
        "/usr/bin/rclone mount nzbdav: ${mountPoint}"
        + " --uid=0 --gid=0 --allow-other --links --use-cookies"
        + " --vfs-cache-mode=full --vfs-cache-max-size=20G --vfs-cache-max-age=24h"
        + " --buffer-size=0M --vfs-read-ahead=512M --dir-cache-time=20s";
    };
    unitConfig = {
      After = [
        containers.media-gluetun.ref
        containers.nzbdav.ref
      ];
      Requires = [
        containers.media-gluetun.ref
        containers.nzbdav.ref
      ];
    };
  };
}
