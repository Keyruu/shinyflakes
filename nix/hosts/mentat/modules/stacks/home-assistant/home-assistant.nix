{ config, ... }:
let
  my = config.services.my.home-assistant;
in
{
  imports = [
    ./config
  ];

  boot.kernel.sysctl = {
    "net.ipv4.igmp_max_memberships" = 50;
  };

  networking.firewall = {
    allowedTCPPorts = [
      8123
      51827
    ];
    allowedUDPPorts = [ 5353 ];
  };

  services.my.home-assistant =
    let
      domain = "hass.peeraten.net";
    in
    {
      port = 8123;
      inherit domain;
      proxy = {
        enable = true;
        cert = {
          provided = false;
          host = domain;
        };
      };
      backup.enable = true;
      stack = {
        enable = true;
        directories = [ "config" ];
        security.enable = false;
        containers.home-assistant = {
          containerConfig = {
            image = "ghcr.io/home-assistant/home-assistant:2026.3.1";
            environments = {
              TZ = "Europe/Berlin";
              OPENAI_BASE_URL = "https://api.mistral.ai/v1";
            };
            exposePorts = [
              "8123"
              "5353"
            ];
            addCapabilities = [
              "CAP_NET_RAW"
              "NET_ADMIN"
              "NET_RAW"
            ];
            devices = [
            ];
            volumes = [
              "${my.stack.path}/config:/config"
              "${my.stack.path}/config/configuration.yaml:/config/configuration.yaml:ro"
              "/run/dbus:/run/dbus:ro"
              "/etc/localtime:/etc/localtime:ro"
            ];
            networks = [
              "host"
            ];
          };
          unitConfig = {
            X-RestartTrigger = [
              "${config.environment.etc."stacks/home-assistant/config/configuration.yaml".source}"
            ];
          };
        };
      };
    };
}
