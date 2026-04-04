{ config, ... }:
let
  my = config.services.my.scanservjs;
in
{
  hardware.sane = {
    enable = true;
    brscan4 = {
      enable = true;
    };
  };

  services.saned = {
    enable = true;
    extraConfig = ''
      10.0.0.0/8
      172.16.0.0/12
    '';
  };

  # Allow the scanservjs container to reach saned on the host
  networking.firewall.interfaces."podman0".allowedTCPPorts = [ 6566 ];

  services.my.scanservjs = {
    port = 8070;
    domain = "scan.port.peeraten.net";
    proxy = {
      enable = true;
      cert.host = "port.peeraten.net";
    };
    stack = {
      enable = true;
      directories = [
        "scans"
        "scans/lucas"
        "scans/nadine"
        "config"
      ];
      security.enable = true;

      containers.scanservjs = {
        containerConfig = {
          image = "docker.io/sbs20/scanservjs:v3.0.4";
          publishPorts = [ "127.0.0.1:${toString my.port}:8080" ];
          environments = {
            SANED_NET_HOSTS = "host.containers.internal";
          };
          addHosts = [ "host.containers.internal:host-gateway" ];
          volumes = [
            "${my.stack.path}/scans:/scans"
            "${my.stack.path}/config:/etc/scanservjs"
          ];
        };
        # scanservjs runs as root and needs to write to data/ and tmp dirs
        security = {
          readOnlyRootFilesystem = false;
          dropAllCapabilities = false;
        };
      };
    };
  };

  environment.etc."stacks/scanservjs/config/config.local.js" = {
    text = # js
      ''
        const options = { paths: ['/usr/lib/scanservjs'] };
        const Process = require(require.resolve('./server/classes/process', options));

        module.exports = {
          actions: [
            {
              name: 'Send to Lucas',
              async execute(fileInfo) {
                return await Process.spawn("cp '" + fileInfo.fullname + "' /scans/lucas/");
              }
            },
            {
              name: 'Send to Nadine',
              async execute(fileInfo) {
                return await Process.spawn("cp '" + fileInfo.fullname + "' /scans/nadine/");
              }
            }
          ]
        };
      '';
  };

  virtualisation.quadlet.containers.scanservjs.unitConfig."X-RestartTrigger" = [
    config.environment.etc."stacks/scanservjs/config/config.local.js".source
  ];
}
