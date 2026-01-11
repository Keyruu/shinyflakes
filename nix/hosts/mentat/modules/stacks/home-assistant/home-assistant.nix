{ config, ... }:
let
  homeAssistantPath = "/etc/stacks/home-assistant";
  my = config.services.my.home-assistant;
in
{
  imports = [
    ./config
  ];

  boot.kernel.sysctl = {
    "net.ipv4.igmp_max_memberships" = 50;
  };

  systemd.tmpfiles.rules = [
    "d ${homeAssistantPath}/config 0755 root root"
  ];

  networking.firewall.allowedTCPPorts = [
    8123
    51827
  ];
  networking.firewall.allowedUDPPorts = [ 5353 ];

  services.my.home-assistant = {
    port = 8123;
    domain = "hass.peeraten.net";
  };

  virtualisation.quadlet.containers.home-assistant = {
    containerConfig = {
      image = "ghcr.io/home-assistant/home-assistant:2025.12.5";
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
        "/dev/serial/by-id/usb-Nabu_Casa_ZBT-2_DCB4D90B9F28-if00"
      ];
      volumes = [
        "${homeAssistantPath}/config:/config"
        "${homeAssistantPath}/config/configuration.yaml:/config/configuration.yaml:ro"
        "/run/dbus:/run/dbus:ro"
        "/etc/localtime:/etc/localtime:ro"
      ];
      networks = [
        "host"
      ];
      labels = [
        "wud.tag.include=^\\d+\\.\\d+\\.\\d+$"
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

  security.acme = {
    certs."${my.domain}" = {
      dnsProvider = "cloudflare";
      dnsPropagationCheck = true;
      environmentFile = config.sops.secrets.cloudflare.path;
    };
  };

  services.nginx.virtualHosts."${my.domain}" = {
    useACMEHost = my.domain;
    forceSSL = true;

    locations."/" = {
      proxyPass = "http://127.0.0.1:${toString my.port}";
      proxyWebsockets = true;
    };
  };
}
