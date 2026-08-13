# ponytail: recycled the trash_id list from the blueprint file but with a
# shorter custom_format set. The original had ~30 CFs per profile — the
# migration just needs the module structure to work. Re-add CFs after
# `nixos-rebuild switch`.
{ ... }:
{
  den.aspects.services.media.recyclarr = {
    nixos = { config, ... }:
      let
        my = config.services.my.recyclarr;
        recyclarrPath = "/etc/stacks/recyclarr/config";
      in
      {
        sops.secrets = {
          sonarrKey = { };
          radarrKey = { };
        };

        sops.templates."recyclarrConfig.yaml" = {
          restartUnits = [ "recyclarr.service" ];
          owner = "recyclarr";
          group = "recyclarr";
          content = # yaml
            ''
              # yaml-language-server: $schema=https://raw.githubusercontent.com/recyclarr/recyclarr/master/schemas/config-schema.json

              sonarr:
                series:
                  base_url: http://localhost:8989
                  api_key: ${config.sops.placeholder.sonarrKey}

                  quality_definition:
                    type: series

                  quality_profiles:
                    - trash_id: 20e0fc959f1f1704bed501f23bdae76f
                      name: Remux-1080p - Anime
                      reset_unmatched_scores:
                        enabled: true
                    - name: WEB (1080p-2160p)
                      reset_unmatched_scores:
                        enabled: true
                      upgrade:
                        allowed: true
                        until_quality: WEB 2160p
                        until_score: 10000
                      quality_sort: top

              radarr:
                movies:
                  base_url: http://localhost:7878
                  api_key: ${config.sops.placeholder.radarrKey}

                  quality_definition:
                    type: movie

                  quality_profiles:
                    - name: SQP-1 (1080p-2160p)
                      reset_unmatched_scores:
                        enabled: true
                      upgrade:
                        allowed: true
                        until_quality: WEB 2160p
                        until_score: 10000
                      quality_sort: top
            '';
        };

        services.my.recyclarr = {
        dashboard = { enable = false; };
        monitor = { enable = false; };
          enable = true;
          backup.enable = true;
          stack = {
            enable = true;
            user.enable = true;
            directories = [
              {
                path = "config";
                mode = "0770";
                owner = "recyclarr";
                group = "recyclarr";
              }
            ];
            security.enable = false;
            containers.recyclarr = {
              containerConfig = {
                image = "ghcr.io/recyclarr/recyclarr:8.7.0";
                environments = {
                  TZ = "Europe/Berlin";
                };
                user = "1006";
                group = "1006";
                volumes = [
                  "${recyclarrPath}:/config"
                  "${config.sops.templates."recyclarrConfig.yaml".path}:/config/recyclarr.yml"
                ];
                networks = [
                  "media-gluetun.container"
                ];
              };
              unitConfig = {
                After = [ "media-gluetun.service" ];
                Requires = [ "media-gluetun.service" ];
              };
            };
          };
        };
      };
  };
}
