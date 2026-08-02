{
  config,
  pkgs,
  lib,
  ...
}:
let
  beszelConfig = {
    systems = [
      {
        name = "prime";
        host = "100.67.0.1";
        port = 45876;
      }
      {
        name = "mentat";
        host = "127.0.0.1";
        port = 45876;
      }
    ];
  };
  configFile = pkgs.writeText "beszel-hub-config.yml" (pkgs.lib.generators.toYAML { } beszelConfig);
in
{
  # Static user so sops-placed SSH keys keep ownership; nixpkgs module's
  # DynamicUser+PrivateUsers would reallocate a UID and lose access to /etc-beszel/.ssh
  users = {
    users.beszel-hub = {
      isSystemUser = true;
      group = "beszel-hub";
    };
    groups.beszel-hub = { };
  };

  services.beszel.hub = {
    enable = true;
    host = "127.0.0.1";
    port = 7220;
    dataDir = "/var/lib/beszel-hub";
  };

  sops.secrets = {
    beszelPrivateKey = {
      owner = "beszel-hub";
      group = "beszel-hub";
      path = "/var/lib/beszel-hub/beszel_data/id_ed25519";
      mode = "0600";
    };
    beszelPublicKey = {
      owner = "beszel-hub";
      group = "beszel-hub";
      path = "/var/lib/beszel-hub/beszel_data/id_ed25519.pub";
      mode = "0644";
    };
  };

  # config.yml auto-registers which systems the hub should track
  environment.etc."beszel-hub/config.yml".source = configFile;

  systemd = {
    services.beszel-hub.serviceConfig = {
      DynamicUser = lib.mkForce false;
      PrivateUsers = lib.mkForce false;
    };
    tmpfiles.rules = [
      "r /var/lib/beszel-hub/beszel_data/config.yml"
      "L+ /var/lib/beszel-hub/beszel_data/config.yml - - - - /etc/beszel-hub/config.yml"
    ];
    services.beszel-hub.restartTriggers = [
      configFile
      config.sops.secrets.beszelPrivateKey.path
      config.sops.secrets.beszelPublicKey.path
    ];
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
