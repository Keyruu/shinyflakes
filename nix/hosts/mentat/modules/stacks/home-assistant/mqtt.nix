{
  config,
  flake,
  ...
}:
let
  stackPath = "/etc/stacks/mqtt/data";
  inherit (config.virtualisation.quadlet) containers;
  inherit (flake.lib) quadlet;
in
{
  sops = {
    secrets = {
      mqttPasswordFile = {
        owner = "mosquitto";
        group = "mosquitto";
      };
    };
    templates."mqtt.conf" = {
      restartUnits = [ (quadlet.service containers.mqtt) ];
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

  services.my.mqtt = {
    enable = true;
    port = 1883;
    backup.enable = true;
    stack = {
      enable = true;
      network.enable = true;
      user = {
        enable = true;
        name = "mosquitto";
        group = "mosquitto";
        uid = 1883;
        gid = 1883;
      };
      directories = [ "data" ];
      security.enable = false;
      containers.mqtt = {
        containerConfig = {
          image = "eclipse-mosquitto:2.0.22";
          publishPorts = [
            "127.0.0.1:1883:1883"
            "192.168.100.7:1883:1883"
          ];
          volumes = [
            "${stackPath}:/mosquitto"
            "${config.sops.templates."mqtt.conf".path}:/mosquitto/config/mqtt.conf:ro"
            "${config.sops.secrets.mqttPasswordFile.path}:/mosquitto/config/pwfile:ro"
          ];
          exec = "mosquitto -c /mosquitto/config/mqtt.conf";
          networkAliases = [ "mqtt" ];
        };
      };
    };
  };
}
