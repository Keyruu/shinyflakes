{ ... }:
{
  den.aspects.services.karaoke = {
    nixos = { config, ... }:
      let
        karaokeDomain = "einfachnextlevel.karaoke.keyruu.de";
      in
      {
        sops.secrets = {
          karaokeAdminPassword = { };
          karaokeCookies = {
            mode = "0444";
          };
        };
        sops.templates."pikaraoke.env" = {
          restartUnits = [
            "karaoke.service"
          ];
          content = ''
            KARAOKE_ADMIN_PASSWORD=${config.sops.placeholder.karaokeAdminPassword}
          '';
        };

        services.my.karaoke = {
        dashboard = { enable = false; };
        monitor = { enable = false; };
          stack = {
            enable = true;
            directories = [
              {
                path = "songs";
                mode = "0755";
                owner = "1000";
                group = "1000";
              }
            ];
            security.enable = false;

            containers = {
              karaoke = {
                containerConfig = {
                  image = "docker.io/vicwomg/pikaraoke:1.21.0";
                  publishPorts = [ "${config.services.mesh.ip}:5555:5555" ];
                  entrypoint = [
                    "/bin/sh"
                    "-c"
                    ''
                      cp /app/cookies-ro.txt /tmp/cookies.txt
                      chmod 644 /tmp/cookies.txt
                      exec pikaraoke \
                        -u "https://${karaokeDomain}" \
                        --admin-password "$KARAOKE_ADMIN_PASSWORD" \
                        --limit-user-songs-by 3 \
                        --ytdl-args "--cookies /tmp/cookies.txt"
                    ''
                  ];
                  volumes = [
                    "/etc/stacks/karaoke/songs:/home/pikaraoke/pikaraoke-songs"
                    "${config.sops.secrets.karaokeCookies.path}:/app/cookies-ro.txt:ro"
                  ];
                  environmentFiles = [ config.sops.templates."pikaraoke.env".path ];
                };
              };
            };
          };
        };
      };
  };
}
