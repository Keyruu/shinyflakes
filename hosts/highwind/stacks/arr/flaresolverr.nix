{...}: {
  virtualisation.quadlet.containers.torrent-flaresolverr = {
    containerConfig = {
      image = "ghcr.io/flaresolverr/flaresolverr:v3.3.21";
      environments = {
        LOG_LEVEL = "info";
        LOG_HTML = "false";
        CAPTCHA_SOLVER = "none";
        TZ = "Europe/Berlin";
      };
      networks = [
        "torrent--gluetun.container"
      ];
    };
    serviceConfig = {
      Restart = "always";
    };
    unitConfig = {
      After = [ "torrent--gluetun.service" ];
      Requires = [ "torrent--gluetun.service" ];
    };
  };
}
