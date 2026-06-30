{ config, flake, ... }:
let
  my = config.services.my.zennotes;
  inherit (config.virtualisation.quadlet) containers;
  inherit (flake.lib) quadlet;
in
{
  sops.secrets.zennotesToken = { };

  sops.templates."zennotes.env" = {
    restartUnits = [ (quadlet.service containers.zennotes) ];
    content = ''
      ZENNOTES_AUTH_TOKEN=${config.sops.placeholder.zennotesToken}
    '';
  };

  services.my.zennotes = {
    port = 7879;
    domain = "notes.lab.keyruu.de";
    proxy.enable = true;
    backup.enable = true;
    stack = {
      enable = true;
      user = {
        enable = true;
        name = "zennotes";
        uid = 1008;
        group = "zennotes";
        gid = 1008;
      };
      directories = [
        "vault"
        "data"
      ];
      security.enable = true;

      containers = {
        zennotes = {
          containerConfig = {
            image = "docker.io/adibhanna/zennotes:2.8.0";
            publishPorts = [ "127.0.0.1:${toString my.port}:7878" ];
            user = "${toString my.stack.user.uid}:${toString my.stack.user.gid}";
            volumes = [
              "${my.stack.path}/vault:/workspace"
              "${my.stack.path}/data:/data"
            ];
            environments = {
              ZENNOTES_BIND = "0.0.0.0:7878";
              ZENNOTES_VAULT_PATH = "/workspace";
              ZENNOTES_CONFIG_PATH = "/data/server.json";
              ZENNOTES_BEHIND_TLS = "1";
            };
            environmentFiles = [ config.sops.templates."zennotes.env".path ];
          };
        };
      };
    };
  };
}
