{ config, flake, ... }:
let
  my = config.services.my.traccar;
  inherit (config.virtualisation.quadlet) containers;
  inherit (flake.lib) quadlet;
in
{
  sops.secrets = {
    traccarClientSecret.owner = "root";
    locationIqKey.owner = "root";
  };

  sops.templates."traccar.xml" = {
    restartUnits = [ (quadlet.service containers.traccar) ];
    content = ''
      <?xml version='1.0' encoding='UTF-8'?>
      <!DOCTYPE properties SYSTEM 'http://java.sun.com/dtd/properties.dtd'>
      <properties>
          <entry key='database.driver'>org.h2.Driver</entry>
          <entry key='database.password'></entry>
          <entry key='database.url'>jdbc:h2:/opt/traccar/data/database</entry>
          <entry key='database.user'>sa</entry>
          <entry key='logger.console'>true</entry>
          <entry key='media.path'>/opt/traccar/data/media</entry>
          <entry key='openid.clientId'>traccar</entry>
          <entry key='openid.clientSecret'>${config.sops.placeholder.traccarClientSecret}</entry>
          <entry key='openid.issuerUrl'>https://auth.peeraten.net/oauth2/openid/traccar</entry>
          <entry key='templates.root'>/opt/traccar/data/templates</entry>
          <entry key='web.address'>0.0.0.0</entry>
          <entry key='web.port'>5785</entry>
          <entry key='web.url'>https://traccar.peeraten.net</entry>
          <entry key='owntracks.port'>5144</entry>
          <entry key='geocoder.enable'>true</entry>
          <entry key='geocoder.type'>nominatim</entry>
          <entry key='geocoder.url'>https://eu1.locationiq.com/v1/reverse.php</entry>
          <entry key='geocoder.key'>${config.sops.placeholder.locationIqKey}</entry>
          <entry key='geocoder.onRequest'>false</entry>
          <entry key='geocoder.ignorePositions'>false</entry>
          <entry key='geocoder.reuseDistance'>10</entry>
      </properties>
    '';
  };

  services.my.traccar = {
    port = 5785;
    stack = {
      enable = true;
      directories = [
        "data"
        "logs"
      ];
      security.enable = false;

      containers = {
        traccar = {
          containerConfig = {
            image = "docker.io/traccar/traccar:6.13-alpine";
            volumes = [
              "${my.stack.path}/data:/opt/traccar/data"
              "${my.stack.path}/logs:/opt/traccar/logs"
              "${config.sops.templates."traccar.xml".path}:/opt/traccar/conf/traccar.xml:ro"
            ];
            publishPorts = [
              "127.0.0.1:5785:5785"
              "${config.services.mesh.ip}:5785:5785"
              "127.0.0.1:5144:5144"
              "${config.services.mesh.ip}:5144:5144"
            ];
          };
        };
      };
    };
  };

  security.acme.certs = {
    "traccar.peeraten.net" = {
      dnsProvider = "cloudflare";
      dnsPropagationCheck = true;
      environmentFile = config.sops.secrets.cloudflare.path;
    };
    "owntracks.peeraten.net" = {
      dnsProvider = "cloudflare";
      dnsPropagationCheck = true;
      environmentFile = config.sops.secrets.cloudflare.path;
    };
  };

  services.nginx.virtualHosts = {
    "traccar.peeraten.net" = {
      useACMEHost = "traccar.peeraten.net";
      forceSSL = true;

      locations."/" = {
        proxyPass = "http://127.0.0.1:5785";
        proxyWebsockets = true;
      };
    };

    "owntracks.peeraten.net" = {
      useACMEHost = "owntracks.peeraten.net";
      forceSSL = true;

      locations."/" = {
        proxyPass = "http://127.0.0.1:5144";
        proxyWebsockets = true;
      };
    };
  };
}
