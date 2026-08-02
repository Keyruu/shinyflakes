{
  config,
  pkgs,
  lib,
  ...
}:
let
  configFile =
    pkgs.writeText "beszel-hub-config.yml" # yaml
      ''
        systems:
          - name: prime
            host: 100.67.0.1
            port: 45876
          - name: mentat
            host: 127.0.0.1
            port: 45876
      '';
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
      path = "/var/lib/beszel-hub/.ssh/id_ed25519";
      mode = "0600";
    };
    beszelPublicKey = {
      owner = "beszel-hub";
      group = "beszel-hub";
      path = "/var/lib/beszel-hub/.ssh/id_ed25519.pub";
      mode = "0644";
    };
  };

  # config.yml auto-registers which systems the hub should track
  environment.etc."beszel-hub/config.yml".source = configFile;

  systemd = {
    services.beszel-hub.serviceConfig = {
      DynamicUser = lib.mkForce false;
      PrivateUsers = lib.mkForce false;
      ExecStartPre = lib.mkBefore [
        "${pkgs.coreutils}/bin/install -m 0640 -o beszel-hub -g beszel-hub ${configFile} /var/lib/beszel-hub/config.yml"
      ];
    };
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
