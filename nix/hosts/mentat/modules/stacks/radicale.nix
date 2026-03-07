{ config, ... }:
let
  my = config.services.my.radicale;
in
{
  users.groups.radicale.gid = 2999;
  users.users.radicale = {
    uid = 2999;
    isSystemUser = true;
    group = "radicale";
  };

  sops.secrets.radicaleUsers = {
    mode = "0440";
    owner = "radicale";
    group = "radicale";
  };

  environment.etc."stacks/radicale/config/config".text = # ini
    ''
      [server]
      hosts = 0.0.0.0:${toString my.port}

      [auth]
      type = htpasswd
      htpasswd_filename = /config/users
      htpasswd_encryption = bcrypt

      [storage]
      filesystem_folder = /data/collections
    '';

  services.my.radicale =
    let
      domain = "calendar.peeraten.net";
    in
    {
      enable = true;
      port = 5232;
      inherit domain;
      proxy = {
        enable = true;
        cert = {
          provided = false;
          host = domain;
        };
      };
      backup.enable = true;
      stack = {
        enable = true;
        user = {
          enable = true;
          uid = 2999;
          gid = 2999;
        };
        directories = [
          {
            path = "data";
            mode = "0750";
            owner = "radicale";
            group = "radicale";
          }
          {
            path = "config";
            mode = "0750";
            owner = "radicale";
            group = "radicale";
          }
        ];
        security.enable = false;

        containers = {
          radicale = {
            containerConfig = {
              image = "tomsquest/docker-radicale:3.6.1.0";
              publishPorts = [
                "127.0.0.1:${toString my.port}:5232"
                "${config.services.mesh.ip}:${toString my.port}:5232"
              ];
              volumes = [
                "${my.stack.path}/data:/data"
                "${my.stack.path}/config/config:/config/config:ro"
                "${config.sops.secrets.radicaleUsers.path}:/config/users:ro"
              ];
            };
            unitConfig = {
              X-RestartTrigger = [
                "${config.environment.etc."stacks/radicale/config/config".source}"
              ];
            };
          };
        };
      };
    };
}
