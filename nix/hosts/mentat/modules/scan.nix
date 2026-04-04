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
        "output"
        "output/lucas"
        "output/nadine"
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
            "${my.stack.path}/output:/var/lib/scanservjs/output"
            "${my.stack.path}/config:/etc/scanservjs"
          ];
        };
        # scanservjs needs longer timeouts for scanning
        security.readOnlyRootFilesystem = false;
      };
    };
  };

  environment.etc."stacks/scanservjs/config/config.local.js" = {
    text = ''
      module.exports = {
        afterConfig(config) {
          config.pipelines = [
            {
              extension: 'pdf',
              description: 'Lucas - PDF',
              commands: [
                'convert @- -quality 92 tmp-%04d.jpg && ls tmp-*.jpg',
                'convert @- scan-0000.pdf',
                'mv scan-0000.pdf ../output/lucas/ && ls ../output/lucas/scan-0000.pdf'
              ]
            },
            {
              extension: 'pdf',
              description: 'Nadine - PDF',
              commands: [
                'convert @- -quality 92 tmp-%04d.jpg && ls tmp-*.jpg',
                'convert @- scan-0000.pdf',
                'mv scan-0000.pdf ../output/nadine/ && ls ../output/nadine/scan-0000.pdf'
              ]
            },
            {
              extension: 'jpg',
              description: 'Lucas - JPG',
              commands: [
                'convert @- -quality 92 scan-%04d.jpg',
                'ls scan-*.jpg'
              ],
              afterAction: 'Move to Lucas'
            },
            {
              extension: 'jpg',
              description: 'Nadine - JPG',
              commands: [
                'convert @- -quality 92 scan-%04d.jpg',
                'ls scan-*.jpg'
              ],
              afterAction: 'Move to Nadine'
            }
          ];
        },

        afterDevices(devices) {
          // Fix Brother scanner dimensions (they often report incorrectly)
          devices
            .filter(d => d.id.includes('brother'))
            .forEach(device => {
              device.features['-l'].limits = [0, 215];
              device.features['-t'].limits = [0, 297];
              device.features['-x'].default = 215;
              device.features['-x'].limits = [0, 215];
              device.features['-y'].default = 297;
              device.features['-y'].limits = [0, 297];
            });
        },

        actions: [
          {
            name: 'Move to Lucas',
            async execute(fileInfo) {
              const options = { paths: ['/usr/lib/scanservjs'] };
              const Process = require(require.resolve('./server/classes/process', options));
              return await Process.spawn("mv '" + fileInfo.fullname + "' /var/lib/scanservjs/output/lucas/");
            }
          },
          {
            name: 'Move to Nadine',
            async execute(fileInfo) {
              const options = { paths: ['/usr/lib/scanservjs'] };
              const Process = require(require.resolve('./server/classes/process', options));
              return await Process.spawn("mv '" + fileInfo.fullname + "' /var/lib/scanservjs/output/nadine/");
            }
          }
        ]
      };
    '';
  };

  virtualisation.quadlet.containers.scanservjs-scanservjs.unitConfig."X-RestartTrigger" = [
    config.environment.etc."stacks/scanservjs/config/config.local.js".source
  ];
}
