{ config, ... }:
let
  stackPath = "/etc/stacks/z2m/data";
  my = config.services.my.zigbee2mqtt;
in
{
  systemd.tmpfiles.rules = [
    "d ${stackPath} 0755 root root"
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

  services.my.zigbee2mqtt = {
    port = 3845;
    domain = "z2m.port.peeraten.net";
    proxy = {
      enable = true;
      cert.host = "port.peeraten.net";
    };
    backup = {
      enable = true;
      paths = [ stackPath ];
    };
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
              "127.0.0.1:${toString my.port}:8080"
            ];
            volumes = [
              "${stackPath}:/app/data"
              "${config.sops.templates."z2mConfiguration.yaml".path}:/app/data/configuration.yaml:ro"
              "/run/udev:/run/udev:ro"
            ];
            networks = [ networks.mqtt.ref ];
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
}
