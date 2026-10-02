{ ... }:
{
  den.aspects.services.home-assistant.openthread = {
    nixos = { config, ... }:
      let
        my = config.services.my.openthread;
        zbt2 = "/dev/serial/by-id/usb-Nabu_Casa_ZBT-2_DCB4D90B9F28-if00";
      in
      {
        services.my.openthread = {
        dashboard = { enable = false; };
        monitor = { enable = false; };
          port = 8981;
          backup.enable = true;
          stack = {
            enable = true;
            directories = [ "data" ];
            security.enable = false;
            containers.openthread = {
              containerConfig = {
                image = "docker.io/openthread/border-router:latest@sha256:6cbaeb3114038817c085b2d3e5fb1a0b50548b2d6839715eeb720dfd75d58d36";
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
                  "${my.stack.path}/data:/data"
                ];
                networks = [
                  "host"
                ];
              };
            };
          };
        };
      };
  };
}
