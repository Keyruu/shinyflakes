{ config, ... }:
let
  stackPath = "/etc/stacks/openthread";
  my = config.services.my.openthread;
  zbt2 = "/dev/serial/by-id/usb-Nabu_Casa_ZBT-2_DCB4D90B9F28-if00";
in
{
  systemd.tmpfiles.rules = [
    "d ${stackPath}/data 0755 root root"
  ];

  services.my.openthread = {
    port = 8981;
    backup = {
      enable = true;
      paths = [ stackPath ];
    };
  };

  virtualisation.quadlet.containers.openthread = {
    containerConfig = {
      image = "docker.io/openthread/border-router:latest@sha256:b7156995ff3b59e5a8c7f9bfaca0b6af57b168a6c09e795e038ef0d8a84f7a4e";
      environments = {
        TZ = "Europe/Berlin";
        OT_RCP_DEVICE = "spinel+hdlc+uart:///dev/ttyACM69?uart-baudrate=460800";
        OT_INFRA_IF = "eth0";
        OT_THREAD_IF = "wpan0";
        OT_LOG_LEVEL = "7";
        OT_REST_PORT = "${toString my.port}";
        OT_REST_LISTEN_PORT = "${toString my.port}";
      };
      devices = [
        "${zbt2}:/dev/ttyACM69"
        "/dev/net/tun"
      ];
      exposePorts = [
        (toString my.port)
      ];
      addCapabilities = [
        "NET_ADMIN"
        "NET_RAW"
      ];
      volumes = [
        "${stackPath}/data:/data"
      ];
      networks = [
        "host"
      ];
    };
    serviceConfig = {
      Restart = "always";
    };
  };
}
