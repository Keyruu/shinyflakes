{ config, lib, pkgs, ... }:
let
  my = config.services.my.scanservjs;
  scansPath = "${my.stack.path}/scans";
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
}
