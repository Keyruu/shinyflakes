{ config, pkgs, ... }:
let
  my = config.services.my.print;
in
{
  services = {
    my.print = {
      port = 631;
      domain = "print.port.peeraten.net";
      proxy = {
        enable = true;
        cert.host = "port.peeraten.net";
      };
    };
    printing = {
      enable = true;
      drivers = with pkgs; [
        brlaser
      ];
      listenAddresses = [
        "192.168.100.7:631"
        "127.0.0.1:${toString my.port}"
      ];
      allowFrom = [ "192.168.100.0/24" ];
      browsing = true;
      defaultShared = true;
      openFirewall = true;
      extraConf = ''
        ServerAlias ${my.domain}
      '';
    };
    avahi = {
      enable = true;
      nssmdns4 = true;
      openFirewall = true;
      publish = {
        enable = true;
        userServices = true;
      };
    };

    # Override the auto-generated nginx proxy to add CUPS-specific headers
    nginx.virtualHosts.${my.domain} = {
      locations."/" = {
        extraConfig = ''
          proxy_set_header Host $host;
          proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
          proxy_set_header X-Forwarded-Proto $scheme;
        '';
      };
    };
  };
}
