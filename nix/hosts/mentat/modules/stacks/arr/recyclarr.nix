{ config, ... }:
let
  recyclarrPath = "/etc/stacks/recyclarr/config";
in
{
  systemd.tmpfiles.rules = [
    "d ${recyclarrPath} 0755 root root"
  ];

  sops.templates."recyclarrConfig.yaml" = {
    restartUnits = [ "torrent-recyclarr.service" ];
    content = # yaml
      ''
        # yaml-language-server: $schema=https://raw.githubusercontent.com/recyclarr/recyclarr/master/schemas/config-schema.json

        sonarr:
          series:
            base_url: http://localhost:8989
            api_key: ${config.sops.placeholder.sonarrKey}

            replace_existing_custom_formats: true

            quality_definition:
                type: series
            include:
                - template: sonarr-quality-definition-series
                - template: sonarr-v4-quality-profile-anime
                - template: sonarr-v4-custom-formats-anime
                - template: sonarr-v4-quality-profile-web-2160p
                - template: sonarr-v4-custom-formats-web-2160p
            quality_profiles:
                - name: Remux-1080p - Anime
                - name: WEB-2160p
                  qualities:
                    - name: WEB 2160p
                      qualities:
                        - WEBDL-2160p
                        - WEBRip-2160p
                    - name: WEB 1080p
                      qualities:
                        - WEBDL-1080p
                        - WEBRip-1080p
            custom_formats:
                # =================================
                # Remux-1080p - Anime
                # =================================
                - trash_ids:
                    # Uncensored
                    - 026d5aadd1a6b4e550b134cb6c72b3ca
                    # 10bit
                    - b2550eb333d27b75833e25b8c2557b38
                    # Anime Dual Audio
                    - 418f50b10f1907201b6cfdf881f467b7
                  assign_scores_to:
                    - name: Remux-1080p - Anime
                # =================================
                # WEB-2160p
                # =================================
                # Optional
                - trash_ids:
                    # Bad Dual Groups
                    - 32b367365729d530ca1c124a0b180c64
                    # DV (WEBDL)
                    - 9b27ab6498ec0f31a3353992e19434ca
                    # No-RlsGroup
                    - 82d40da2bc6923f41e14394075dd4b03
                  assign_scores_to:
                    - name: WEB-2160p

        radarr:
          movies:
            base_url: http://localhost:7878
            api_key: ${config.sops.placeholder.radarrKey}

            replace_existing_custom_formats: true

            quality_profiles:
              - name: SQP-1 (1080p)
                min_format_score: 10
              - name: SQP-1 (2160p)
              # Uncomment the below line if you don't have access to top-tier indexers
                min_format_score: 10

            include:
              # Comment out any of the following includes to disable them
              - template: radarr-quality-definition-sqp-streaming

              - template: radarr-quality-profile-sqp-1-1080p
              - template: radarr-custom-formats-sqp-1-1080p

              - template: radarr-quality-profile-sqp-1-2160p-default
              - template: radarr-custom-formats-sqp-1-2160p

            custom_formats:
              - trash_ids:
                  - dc98083864ea246d05a42df0d05f81cc # x265 (HD)
                assign_scores_to:
                  - name: SQP-1 (1080p)
      '';
  };

  virtualisation.quadlet.containers.torrent-recyclarr = {
    containerConfig = {
      image = "ghcr.io/recyclarr/recyclarr:7.5.2";
      environments = {
        TZ = "Europe/Berlin";
      };
      user = "root";
      volumes = [
        "${recyclarrPath}:/config"
        "${config.sops.templates."recyclarrConfig.yaml".path}:/config/recyclarr.yml:ro"
      ];
      networks = [
        "torrent-gluetun.container"
      ];
      labels = [
        "wud.tag.include=^\\d+\\.\\d+\\.\\d+$"
      ];
    };
    serviceConfig = {
      Restart = "always";
    };
    unitConfig = {
      After = [ "torrent-gluetun.service" ];
      Requires = [ "torrent-gluetun.service" ];
    };
  };
}
