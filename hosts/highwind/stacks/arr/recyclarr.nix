{ config, ... }:
let
  recyclarrPath = "/etc/stacks/recyclarr/config";
in
{
  systemd.tmpfiles.rules = [
    "d ${recyclarrPath} 0755 root root"
  ];

  sops.templates."recyclarrConfig.yaml".content = # yaml
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
          # 1080p
            - trash_ids:
            # Uncomment any of the next six lines to prefer these movie versions
                # - 570bc9ebecd92723d2d21500f4be314c # Remaster
                # - eca37840c13c6ef2dd0262b141a5482f # 4K Remaster
                # - e0c07d59beb37348e975a930d5e50319 # Criterion Collection
                # - 9d27d9d2181838f76dee150882bdc58c # Masters of Cinema
                # - db9b4c4b53d312a3ca5f1378f6440fc9 # Vinegar Syndrome
                # - 957d0f44b592285f26449575e8b1167e # Special Edition
            # Uncomment the next line if you prefer WEBDL with IMAX Enhanced to BHDStudio
                # - 9f6cbff8cfe4ebbc1bde14c7b7bec0de # IMAX Enhanced

            # Optional - uncomment any of the following if you want them added to your profile
                # - b6832f586342ef70d9c128d40c07b872 # Bad Dual Groups
                # - 90cedc1fea7ea5d11298bebd3d1d3223 # EVO (no WEBDL)
                # - ae9b7c9ebde1f3bd336a8cbd1ec4c5e5 # No-RlsGroup
                # - 7357cf5161efbf8c4d5d0c30b4815ee2 # Obfuscated
                # - 5c44f52a8714fdd79bb4d98e2673be1f # Retags
                # - f537cf427b64c38c8e36298f657e4828 # Scene
              assign_scores_to:
                - name: SQP-1 (1080p)
            - trash_ids:
                - dc98083864ea246d05a42df0d05f81cc # x265 (HD)
              assign_scores_to:
                - name: SQP-1 (1080p)


          # 4K
            - trash_ids:
            # Uncomment any of the next six lines to prefer these movie versions
                # - 570bc9ebecd92723d2d21500f4be314c # Remaster
                # - eca37840c13c6ef2dd0262b141a5482f # 4K Remaster
                # - e0c07d59beb37348e975a930d5e50319 # Criterion Collection
                # - 9d27d9d2181838f76dee150882bdc58c # Masters of Cinema
                # - db9b4c4b53d312a3ca5f1378f6440fc9 # Vinegar Syndrome
                # - 957d0f44b592285f26449575e8b1167e # Special Edition
            # Uncomment the next line if you prefer 1080p/2160p WEBDL with IMAX Enhanced
                # - 9f6cbff8cfe4ebbc1bde14c7b7bec0de # IMAX Enhanced
              assign_scores_to:
                - name: SQP-1 (2160p)

            # Unwanted
            - trash_ids:
            # Uncomment the next six lines to block all x265 HD releases
                # - 839bea857ed2c0a8e084f3cbdbd65ecb # x265 (no HDR/DV)
              # assign_scores_to:
                # - name: SQP-1 (2160p)
                  # score: 0
            # - trash_ids:
                # - dc98083864ea246d05a42df0d05f81cc # x265 (HD)
              assign_scores_to:
                - name: SQP-1 (2160p)

            # Optional
            - trash_ids:
                # Uncomment the next two lines if you have a setup that supports HDR10+
                # - b17886cb4158d9fea189859409975758 # HDR10+ Boost
                # - 55a5b50cb416dea5a50c4955896217ab # DV HDR10+ Boost

                # Uncomment any of the following optional custom formats if you want them to be added to
                # the quality profile
                # - b6832f586342ef70d9c128d40c07b872 # Bad Dual Groups
                # - 90cedc1fea7ea5d11298bebd3d1d3223 # EVO (no WEBDL)
                # - ae9b7c9ebde1f3bd336a8cbd1ec4c5e5 # No-RlsGroup
                # - 7357cf5161efbf8c4d5d0c30b4815ee2 # Obfuscated
                # - 5c44f52a8714fdd79bb4d98e2673be1f # Retags
                # - f537cf427b64c38c8e36298f657e4828 # Scene
              assign_scores_to:
                - name: SQP-1 (2160p)

            # Optional SDR
            # Only ever use ONE of the following custom formats:
            # SDR - block ALL SDR releases
            # SDR (no WEBDL) - block UHD/4k Remux and Bluray encode SDR releases, but allow SDR WEB
            - trash_ids:
                - 9c38ebb7384dada637be8899efa68e6f # SDR
                # - 25c12f78430a3a23413652cbd1d48d77 # SDR (no WEBDL)
              assign_scores_to:
                - name: SQP-1 (2160p)
    '';

  virtualisation.quadlet.containers.torrent-recyclarr = {
    containerConfig = {
      image = "ghcr.io/recyclarr/recyclarr:7.4.1";
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
