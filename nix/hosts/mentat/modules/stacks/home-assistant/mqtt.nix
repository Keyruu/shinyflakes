{ config, ... }:
let
  mqttPath = "/etc/stacks/mqtt/data";
in
{
  systemd.tmpfiles.rules = [
    "d ${mqttPath} 0755 root root"
  ];

  sops = {
    secrets = {
      mqttPasswordFile.mode = "0700";
    };
    templates."mqtt.conf" = {
      restartUnits = [ "mqtt.service" ];
      content = # yaml
        ''
          allow_anonymous false
          listener 1883
          listener 9001
          protocol websockets
          persistence true
          password_file /mosquitto/config/pwfile
          persistence_file mosquitto.db
          persistence_location /mosquitto/data/
        '';
    };
  };

  virtualisation.quadlet =
    let
      inherit (config.virtualisation.quadlet) networks;
    in
    {
      networks.mqtt.networkConfig.driver = "bridge";
      containers = {
        mqtt = {
          containerConfig = {
            image = "eclipse-mosquitto:2.0.22";
            publishPorts = [
              "127.0.0.1:1883:1883"
              "192.168.100.7:1883:1883"
              "127.0.0.1:9001:9001"
            ];
            volumes = [
              "${mqttPath}:/mosquitto"
              "${config.sops.templates."mqtt.conf".path}:/mosquitto/config/mqtt.conf:ro"
              "${config.sops.secrets.mqttPasswordFile.path}:/mosquitto/config/pwfile:ro"
            ];
            exec = "mosquitto -c /mosquitto/config/mqtt.conf";
            networks = [ networks.mqtt.ref ];
            labels = [
              "wud.tag.include=^\\d+\\.\\d+\\.\\d+$"
            ];
          };
          serviceConfig = {
            Restart = "always";
          };
        };
      };
    };

  services.nginx.virtualHosts."mqtt.port.peeraten.net" = {
    useACMEHost = "port.peeraten.net";
    forceSSL = true;

    locations."/" = {
      proxyPass = "http://127.0.0.1:9001";
      proxyWebsockets = true;
    };
  };
}
