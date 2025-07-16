{ config, ... }:
{
  services.nginx.virtualHosts."hass.peeraten.net" = {
    enableACME = true;
    forceSSL = true;

    locations."/" = {
      proxyPass = "http://100.64.0.1:8123";
      proxyWebsockets = true;
      extraConfig = ''
        modsecurity on;
        modsecurity_rules_file /etc/nginx/modsec/main.conf;
      '';
    };
  };

  services.nginx.virtualHosts."traccar.peeraten.net" = {
    enableACME = true;
    forceSSL = true;

    locations."/" = {
      proxyPass = "http://100.64.0.1:5785";
      proxyWebsockets = true;
      extraConfig = ''
        modsecurity on;
        modsecurity_rules_file /etc/nginx/modsec/main.conf;
      '';
    };
  };

  services.nginx.virtualHosts."map.peeraten.net" = {
    enableACME = true;
    forceSSL = true;

    locations."/" = {
      proxyPass = "http://100.64.0.1:3001";
      proxyWebsockets = true;
      extraConfig = ''
        modsecurity on;
        modsecurity_rules_file /etc/nginx/modsec/main.conf;
      '';
    };
  };

  services.nginx.virtualHosts."calendar.peeraten.net" = {
    enableACME = true;
    forceSSL = true;

    locations."/" = {
      proxyPass = "http://100.64.0.1:5232";
      proxyWebsockets = true;
      extraConfig = ''
        modsecurity on;
        modsecurity_rules_file /etc/nginx/modsec/main.conf;
      '';
    };
  };

  services.nginx.virtualHosts."files.keyruu.de" = {
    enableACME = true;
    forceSSL = true;

    locations = {
      "/" = {
        proxyPass = "http://100.64.0.1:9433";
        proxyWebsockets = true;
        extraConfig = ''
          modsecurity on;
          modsecurity_rules_file /etc/nginx/modsec/main.conf;
        '';
      };
      "/dav" = {
        proxyPass = "http://100.64.0.1:9434";
        proxyWebsockets = true;
        extraConfig = ''
          modsecurity on;
          modsecurity_rules_file /etc/nginx/modsec/main.conf;
        '';
      };
    };
  };

  # services.nginx.virtualHosts."immich.keyruu.de" = {
  #   enableACME = true;
  #   forceSSL = true;
  #
  #   locations."/" = {
  #     proxyPass = "http://hati:2283";
  #     proxyWebsockets = true;
  #   };
  # };

  # services.nginx.virtualHosts."*.zimtix.de" = {
  #   locations."/" = {
  #     proxyPass = "http://192.168.100.32:80";
  #     proxyWebsockets = true;
  #   };
  # };
}
