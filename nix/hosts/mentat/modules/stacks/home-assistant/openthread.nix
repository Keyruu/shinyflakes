{ config, ... }:
let
  my = config.services.my.openthread;
  zbt2 = "/dev/serial/by-id/usb-Nabu_Casa_ZBT-2_DCB4D90B9F28-if00";
in
{
  services.my.openthread = {
    port = 8981;
    backup.enable = true;
    stack = {
      enable = true;
      directories = [ "data" ];
      security.enable = false;
      containers.openthread = {
        containerConfig = {
          image = "docker.io/openthread/border-router:latest@sha256:8612d30b244a81671099be1447c8b9a0854f4f328af2b84cea74b844536df090";
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
}
