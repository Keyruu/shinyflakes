{config, ...}: let
  homeAssistantPath = "/etc/stacks/home-assistant";
in {
  imports = [
    ./zigbee2mqtt.nix
    ./matter-hub.nix
    ./esphome.nix
  ];

  boot.kernel.sysctl = {
    "net.ipv4.igmp_max_memberships" = 50;
  };

  systemd.tmpfiles.rules = [
    "d ${homeAssistantPath}/config 0755 root root"
  ];

  environment.etc."stacks/home-assistant/config/configuration.yaml".text = /* yaml */ ''
    # Loads default set of integrations. Do not remove.
    default_config:

    # Load frontend themes from the themes folder
    frontend:
      themes: !include_dir_merge_named themes

    automation: !include automations.yaml
    script: !include scripts.yaml
    scene: !include scenes.yaml

    http:
      use_x_forwarded_for: true
      trusted_proxies:
        - 127.0.0.1
        - 100.64.0.0/10

    zeroconf:
      default_interface: true
  '';

  networking.firewall.allowedTCPPorts = [ 8123 51827 ];
  networking.firewall.allowedUDPPorts = [ 5353 ];

  virtualisation.quadlet.containers.home-assistant = {
    containerConfig = {
      image = "ghcr.io/home-assistant/home-assistant:2025.5.0";
      environments = {
        TZ = "Europe/Berlin";
      };
      exposePorts = [
        "8123"
        "5353"
      ];
      addCapabilities = [
        "CAP_NET_RAW"
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
  };

  security.acme = {
    certs."hass.peeraten.net" = {
      dnsProvider = "cloudflare";
      dnsPropagationCheck = true;
      environmentFile = config.sops.secrets.cloudflare.path;
    };
  };

  services.nginx.virtualHosts."hass.peeraten.net" = {
    useACMEHost = "hass.peeraten.net";
    forceSSL = true;

    locations."/" = {
      proxyPass = "http://127.0.0.1:8123";
      proxyWebsockets = true;
    };
  };
}
