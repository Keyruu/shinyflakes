{config, pkgs, ...}: 
let
  beszelConfig = {
    systems = [
      {
        name = "garm";
        host = "garm";
        port = 45876;
      }
      {
        name = "sleipnir";
        host = "sleipnir";
        port = 45876;
      }
      {
        name = "highwind";
        host = "127.0.0.1";
        port = 45876;
      }
    ];
  };

  beszelConfigYaml = pkgs.lib.generators.toYAML {} beszelConfig;
in {
  environment.etc."beszel/beszel_data/config.yml".text = beszelConfigYaml;

  sops.secrets = {
    beszelPrivateKey = {
      owner = "root";
      path = "/etc/beszel/beszel_data/id_ed25519";
    };
    beszelPublicKey = {
      owner = "root";
      path = "/etc/beszel/beszel_data/id_ed25519.pub";
    };
  };

  systemd.services.beszel-hub = {
    description = "Beszel Hub";
    after = [ "network.target" ];
    wantedBy = [ "multi-user.target" ];
    restartTriggers = [
      config.environment.etc."beszel/beszel_data/config.yml".source
      config.sops.secrets.beszelPrivateKey.path 
      config.sops.secrets.beszelPublicKey.path 
    ];
    serviceConfig = {
      Type = "simple";
      Restart="always";
      RestartSec="3";
      User="root";
      WorkingDirectory="/etc/beszel";
      ExecStart=''${pkgs.beszel}/bin/beszel-hub serve --http "127.0.0.1:7220"'';
    };
  };

  services.nginx.virtualHosts."beszel.lab.keyruu.de" = {
    useACMEHost = "lab.keyruu.de";
    forceSSL = true;

    locations."/" = {
      proxyPass = "http://127.0.0.1:7220";
      proxyWebsockets = true;
    };
  };
}
