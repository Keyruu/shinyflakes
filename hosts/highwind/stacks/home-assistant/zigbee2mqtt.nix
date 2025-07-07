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

  sops.secrets.z2mNetworkKey.owner = "root";
  sops.secrets.z2mPanId.owner = "root";
  sops.secrets.z2mExtraPanId.owner = "root";

  sops.templates."z2mConfiguration.yaml".content = # yaml
    ''
      version: 4
      mqtt:
        base_topic: zigbee2mqtt
        server: mqtt://mqtt
      serial:
        port: /dev/ttyUSB0
        adapter: zstack
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

  virtualisation.quadlet =
    let
      inherit (config.virtualisation.quadlet) networks;
    in
    {
      networks.mqtt.networkConfig.driver = "bridge";
      containers = {
        mqtt = {
          containerConfig = {
            image = "eclipse-mosquitto:2.0.21";
            publishPorts = [
              "127.0.0.1:1883:1883"
              "192.168.100.7:1883:1883"
              "127.0.0.1:9001:9001"
            ];
            volumes = [
              "${mqttPath}:/mosquitto"
            ];
            exec = "mosquitto -c /mosquitto-no-auth.conf";
            networks = [ networks.mqtt.ref ];
            labels = [
              "wud.tag.include=^\\d+\\.\\d+\\.\\d+$"
            ];
          };
          serviceConfig = {
            Restart = "always";
          };
        };

        zigbee2mqtt = {
          containerConfig = {
            image = "koenkk/zigbee2mqtt:2.5.1";
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
              "/dev/serial/by-id/usb-ITead_Sonoff_Zigbee_3.0_USB_Dongle_Plus_9e1108923db6ed1198add80ea8669f5d-if00-port0:/dev/ttyUSB0"
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

  services.nginx.virtualHosts."mqtt.port.peeraten.net" = {
    useACMEHost = "port.peeraten.net";
    forceSSL = true;

    locations."/" = {
      proxyPass = "http://127.0.0.1:9001";
      proxyWebsockets = true;
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
