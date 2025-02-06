{config, ...}: let 
  matterHubPath = "/etc/stacks/matter-hub/data";
in {
  systemd.tmpfiles.rules = [
    "d ${matterHubPath} 0755 root root"
  ];

  sops.secrets.hassKey.owner = "root";

  sops.templates."matterHub.env".content = /* env */ ''
    HAMH_HOME_ASSISTANT_URL=https://hass.peeraten.net
    HAMH_HOME_ASSISTANT_ACCESS_TOKEN=${config.sops.placeholder.hassKey}
    HAMH_LOG_LEVEL=info
    HAMH_HTTP_PORT=8482
  '';

  networking.firewall.allowedTCPPorts = [ 8482 5540 ];
  networking.firewall.allowedUDPPorts = [ 5540 ];

  virtualisation.quadlet.containers.matter-hub = {
    containerConfig = {
      image = "ghcr.io/t0bst4r/home-assistant-matter-hub:latest";
      environments = {
        TZ = "Europe/Berlin";
      };
      environmentFiles = [
        config.sops.templates."matterHub.env".path
      ];
      exposePorts = [
        "8482"
        "5540"
      ];
      addCapabilities = [
        "CAP_NET_RAW"
      ];
      volumes = [
        "${matterHubPath}:/data"
      ];
      networks = [
        "host"
      ];
    };
    serviceConfig = {
      Restart = "always";
    };
  };

  services.nginx.virtualHosts."matter-hub.port.peeraten.net" = {
    useACMEHost = "port.peeraten.net";
    forceSSL = true;

    locations."/" = {
      proxyPass = "http://127.0.0.1:8482";
      proxyWebsockets = true;
    };
  };
}
