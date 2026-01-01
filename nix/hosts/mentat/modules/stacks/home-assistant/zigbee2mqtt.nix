{ config, ... }:
let
  mqttPath = "/etc/stacks/mqtt/data";
  z2mPath = "/etc/stacks/z2m/data";
in
{
  systemd.tmpfiles.rules = [
    "d ${z2mPath} 0755 root root"
    "d ${mqttPath} 0755 root root"
  ];

  sops.secrets = {
    z2mNetworkKey.owner = "root";
    z2mPanId.owner = "root";
    z2mExtraPanId.owner = "root";
    mqttPassword.owner = "root";
  };

  sops.templates."z2mConfiguration.yaml" = {
    restartUnits = [ "zigbee2mqtt.service" ];
    content = # yaml
      ''
        version: 4
        mqtt:
          base_topic: zigbee2mqtt
          server: mqtt://mqtt
          user: mqtt
          password: ${config.sops.placeholder.mqttPassword}
        serial:
          adapter: zstack
          port: /dev/ttyACM0
        advanced:
          channel: 11
          network_key: ${config.sops.placeholder.z2mNetworkKey}
          pan_id: ${config.sops.placeholder.z2mPanId}
          ext_pan_id: ${config.sops.placeholder.z2mExtraPanId}
        frontend:
          enabled: true
          package: zigbee2mqtt-windfront
        homeassistant:
          enabled: true
          experimental_event_entities: true
        devices: devices.yaml
        groups: groups.yaml
      '';
  };

  virtualisation.quadlet =
    let
      inherit (config.virtualisation.quadlet) networks;
    in
    {
      containers = {
        zigbee2mqtt = {
          containerConfig = {
            image = "koenkk/zigbee2mqtt:2.7.2";
            environments = {
              TZ = "Europe/Berlin";
            };
            publishPorts = [
              "127.0.0.1:3845:8080"
            ];
            volumes = [
              "${z2mPath}:/app/data"
              "${config.sops.templates."z2mConfiguration.yaml".path}:/app/data/configuration.yaml:ro"
              "/run/udev:/run/udev:ro"
            ];
            networks = [ networks.mqtt.ref ];
            labels = [
              "wud.tag.include=^\\d+\\.\\d+\\.\\d+$"
            ];
            devices = [
              "/dev/serial/by-id/usb-ITead_Sonoff_Zigbee_3.0_USB_Dongle_Plus_9e1108923db6ed1198add80ea8669f5d-if00-port0:/dev/ttyACM0"
            ];
          };
          serviceConfig = {
            Restart = "always";
          };
          unitConfig = {
            After = "mqtt.service";
            Requires = "mqtt.service";
          };
        };
      };
    };

  services.nginx.virtualHosts."z2m.port.peeraten.net" = {
    useACMEHost = "port.peeraten.net";
    forceSSL = true;

    locations."/" = {
      proxyPass = "http://127.0.0.1:3845";
      proxyWebsockets = true;
    };
  };
}
