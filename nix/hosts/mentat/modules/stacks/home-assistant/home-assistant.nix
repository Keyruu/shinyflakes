{ config, ... }:
let
  homeAssistantPath = "/etc/stacks/home-assistant";
in
{
  boot.kernel.sysctl = {
    "net.ipv4.igmp_max_memberships" = 50;
  };

  systemd.tmpfiles.rules = [
    "d ${homeAssistantPath}/config 0755 root root"
  ];

  environment.etc."stacks/home-assistant/config/configuration.yaml".text = # yaml
    ''
      # Loads default set of integrations. Do not remove.
      default_config:

      # Load frontend themes from the themes folder
      frontend:
        themes: !include_dir_merge_named themes
        extra_module_url:
          - /hacsfiles/custom-sidebar/custom-sidebar-yaml.js

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

      shell_command:
        get_entity_alias: jq '[.data.entities[] | select(.options.conversation.should_expose == true and (.aliases | length > 0)) | {aliases, entity_id}]' ./.storage/core.entity_registry

      template:
        - triggers:
          - trigger: time_pattern
            minutes: 5
          - platform: homeassistant
            event: start
          actions:
            - service: shell_command.get_entity_alias
              data: {}
              response_variable: result
          sensor:
            - name: "Entity IDs mit Alias"
              state: '0'
              attributes:
                entities: "{{result.stdout}}"

      tts:
        - platform: marytts
          host: 127.0.0.1 # IP address of the server
          port: 9898
          codec: WAVE_FILE
          voice: glados # The name of the voice you want to use.
          language: de # The model is multilingual, it only affects the pronunciation accent.
    '';

  networking.firewall.allowedTCPPorts = [
    8123
    51827
  ];
  networking.firewall.allowedUDPPorts = [ 5353 ];

  virtualisation.quadlet.containers.home-assistant = {
    containerConfig = {
      image = "ghcr.io/home-assistant/home-assistant:2025.12.3";
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
