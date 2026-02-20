{ config, ... }:
let
  stackPath = "/etc/stacks/home-assistant";
in
{
  imports = [
    ./config
  ];

  boot.kernel.sysctl = {
    "net.ipv4.igmp_max_memberships" = 50;
  };

  systemd.tmpfiles.rules = [
    "d ${stackPath}/config 0755 root root"
  ];

  networking.firewall.allowedTCPPorts = [
    8123
    51827
  ];
  networking.firewall.allowedUDPPorts = [ 5353 ];

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
      backup = {
        enable = true;
        paths = [ stackPath ];
      };
    };

  virtualisation.quadlet.containers.home-assistant = {
    containerConfig = {
      image = "ghcr.io/home-assistant/home-assistant:2026.2.3";
      environments = {
        TZ = "Europe/Berlin";
        # OPENAI_BASE_URL = "https://api.scaleway.ai/28f14df5-01a1-40d6-b09f-046cadfaf4c9/v1";
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
        # "/dev/serial/by-id/usb-Nabu_Casa_ZBT-2_DCB4D90B9F28-if00"
      ];
      volumes = [
        "${stackPath}/config:/config"
        "${stackPath}/config/configuration.yaml:/config/configuration.yaml:ro"
        "/run/dbus:/run/dbus:ro"
        "/etc/localtime:/etc/localtime:ro"
      ];
      networks = [
        "host"
      ];
    };
    serviceConfig = {
      Restart = "always";
    };
    unitConfig = {
      X-RestartTrigger = [
        "${config.environment.etc."stacks/home-assistant/config/configuration.yaml".source}"
      ];
    };
  };
}
