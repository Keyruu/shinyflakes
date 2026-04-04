{
  config,
  lib,
  pkgs,
  ...
}:
let
  my = config.services.my.scanservjs;
  scansPath = "${my.stack.path}/scans";
  # The scanservjs package path where config/config.local.js is expected
  scanservjsPackagePath = "${pkgs.scanservjs}/lib/node_modules/scanservjs";
in
{
  hardware.sane.brscan4.enable = true;

  services.my.scanservjs = {
    port = 8070;
    domain = "scan.port.peeraten.net";
    proxy = {
      enable = true;
      cert.host = "port.peeraten.net";
    };
    backup.enable = true;
    stack = {
      enable = true;
      directories = [
        "scans"
        "scans/lucas"
        "scans/nadine"
      ];
    };
  };

  services.scanservjs = {
    enable = true;
    settings = {
      host = "127.0.0.1";
      port = my.port;
    };
    extraActions = [
      ''
        {
          name: 'Send to Lucas',
          async execute(fileInfo) {
            const Process = require('./server/classes/process');
            return await Process.spawn("cp '" + fileInfo.fullname + "' '${scansPath}/lucas/'");
          }
        }
      ''
      ''
        {
          name: 'Send to Nadine',
          async execute(fileInfo) {
            const Process = require('./server/classes/process');
            return await Process.spawn("cp '" + fileInfo.fullname + "' '${scansPath}/nadine/'");
          }
        }
      ''
    ];
  };

  # The NixOS module sets NIX_SCANSERVJS_CONFIG_PATH but the package doesn't
  # read it. scanservjs loads config from ../../config/config.local.js relative
  # to its source. We bind-mount the config file into the expected location.
  systemd.services.scanservjs.serviceConfig.BindPaths = [
    "${config.systemd.services.scanservjs.environment.NIX_SCANSERVJS_CONFIG_PATH}:${scanservjsPackagePath}/config/config.local.js"
  ];
}
