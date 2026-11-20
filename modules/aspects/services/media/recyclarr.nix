# Radarr block restored from the blueprint config (SQP-1 scores + 2160p size
# caps). Without it recyclarr only touched upgrade/sort, leaving every CF score
# at 0 and 2160p sizes unlimited (an 85 GiB German multi-film pack was grabbed).
# Sonarr still runs the shortened CF set — re-add its CFs after
# `nixos-rebuild switch`.
{ ... }:
{
  den.aspects.services.media.recyclarr = {
    nixos =
      { config, ... }:
      let
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
                    # Guide leaves 2160p max unlimited, so Radarr always takes the
                    # fattest 4K release. Caps keep this profile at encode-tier
                    # bitrates and reject multi-film packs such as an 85 GiB one.
                    # preferred must stay <= max: recyclarr refuses the guide's
                    # inherited preferred (1999) against a capped max.
                    qualities:
                      - name: Bluray-2160p
                        max: 250
                        preferred: 250
                      - name: WEBDL-2160p
                        max: 200
                        preferred: 200
                      - name: WEBRip-2160p
                        max: 200
                        preferred: 200

                  quality_profiles:
                    # Hybrid: 1080p minimum, auto-upgrade to 2160p; encode-tier (no
                    # remux) cutoff at WEB 2160p = stop upgrading once German DL WEB
                    # 2160p is on disk. score_set pulls the TRaSH SQP-1 (2160p)
                    # scores so releases are actually ranked instead of CF score 0.
                    - name: SQP-1 (1080p-2160p)
                      reset_unmatched_scores:
                        enabled: true
                      min_format_score: 0
                      score_set: sqp-1-2160p
                      upgrade:
                        allowed: true
                        until_quality: WEB 2160p
                        until_score: 10000
                      quality_sort: top
                      qualities:
                        - name: Bluray-2160p
                        - name: WEB 2160p
                          qualities:
                            - WEBDL-2160p
                            - WEBRip-2160p
                        - name: Bluray-1080p
                        - name: WEB 1080p
                          qualities:
                            - WEBDL-1080p
                            - WEBRip-1080p

                  custom_formats:
                    - trash_ids:
                        - dc98083864ea246d05a42df0d05f81cc # x265 (HD)
                      assign_scores_to:
                        - name: SQP-1 (1080p-2160p)

                    - trash_ids:
                        - f845be10da4f442654c13e1f2c3d6cd5 # German DL (default -10000)
                      assign_scores_to:
                        - name: SQP-1 (1080p-2160p)
                          score: 11000

                    - trash_ids:
                        - 86bc3115eb4e9873ac96904a4a68e19e # German
                        - 6aad77771dabe9d3e9d7be86f310b867 # German DL (undefined)
                        - 4eadb75fb23d09dfc0a8e3f687e72287 # Not German or English
                        - 8608a2ed20c636b8a62de108e9147713 # German Remux Tier 01
                        - f9cf598d55ce532d63596b060a6db9ee # German Remux Tier 02
                        - a2ab25194f463f057a5559c03c84a3df # German Web Tier 01
                        - 08d120d5a003ec4954b5b255c0691d79 # German Web Tier 02
                        - 439f9d71becaed589058ec949e037ff3 # German Web Tier 03
                        - 2d136d4e33082fe573d06b1f237c40dd # German Scene
                        - 263943bc5d99550c68aad0c4278ba1c7 # German LQ
                        - a826ee9e46607bc61795c85a6f2b1279 # German LQ (release title)
                        - 03c430f326f10a27a9739b8bc83c30e4 # German Microsized
                      assign_scores_to:
                        - name: SQP-1 (1080p-2160p)

                    - trash_ids:
                        - 3bc8df3a71baaac60a31ef696ea72d36 # German 1080p Booster
                        - cc7b1e64e2513a6a271090cdfafaeb55 # German 2160p Booster
                      assign_scores_to:
                        - name: SQP-1 (1080p-2160p)

                    # SQP-1 (2160p) guide CF set; custom profiles need it explicit.
                    # SDR block omitted (hybrid accepts 1080p SDR); score-0
                    # streaming block omitted.
                    - trash_ids:
                        # Audio
                        - 496f355514737f7d83bf7aa4d24f8169 # TrueHD Atmos
                        - 2f22d89048b01681dde8afe203bf2e95 # DTS X
                        - 417804f7f2c4308c1f4c5d380d4c4475 # ATMOS (undefined)
                        - 1af239278386be2919e1bcee0bde047e # DD+ ATMOS
                        - 3cafb66171b47f226146a0770576870f # TrueHD
                        - dcf3ec6938fa32445f590a4da84256cd # DTS-HD MA
                        - a570d4a0e56a2874b64e5bfa55202a1b # FLAC
                        - e7c2fcae07cbada050a0af3357491d7b # PCM
                        - 8e109e50e0a0b83a5098b056e13bf6db # DTS-HD HRA
                        - 185f1dd7264c4562b9022d963ac37424 # DD+
                        - f9f847ac70a0af62ea4a08280b859636 # DTS-ES
                        - 1c1a4c5e823891c75bc50380a6866f73 # DTS
                        - 240770601cc226190c367ef59aba7463 # AAC
                        - c2998bd0d90ed5621d8df281e839436e # DD

                        # Unified HDR + DV (w/o HDR fallback)
                        - 493b6d1dbec3c3364c59d7607f7e3405 # HDR
                        - 923b6abef9b17f937fab56cfcf89e1f1 # DV (w/o HDR fallback)

                        # HQ Release Groups
                        - 5153ec7413d9dae44e24275589b5e944 # BHDStudio
                        - 7a0d1ad358fee9f5b074af3ef3f9d9ef # hallowed
                        - c20f169ef63c5f40c2def54abaf4438e # WEB Tier 01
                        - 403816d65392c79236dcb6dd591aeda4 # WEB Tier 02
                        - af94e0fe497124d1f9ce732069ec8c3b # WEB Tier 03
                        - ed27ebfef2f323e964fb1f61391bcb35 # HD Bluray Tier 01
                        - c20c8647f2746a1f4c4262b0fbbeeeae # HD Bluray Tier 02
                        - 5608c71bcebba0a5e666223bae8c9227 # HD Bluray Tier 03
                        - 4d74ac4c4db0b64bff6ce0cffef99bf0 # UHD Bluray Tier 01
                        - a58f517a70193f8e578056642178419d # UHD Bluray Tier 02
                        - e71939fae578037e7aed3ee219bbe7c1 # UHD Bluray Tier 03

                        # Misc
                        - e7718d7a3ce595f289bfee26adc178f5 # Repack/Proper
                        - ae43b294509409a6a13919dedd4764c4 # Repack2
                        - 5caaaa1c08c1742aa4342d8c4cc463f2 # Repack3

                        # Unwanted
                        - ed38b889b31be83fda192888e2286d83 # BR-DISK
                        - e6886871085226c3da1830830146846c # Generated Dynamic HDR
                        - 90a6f9a284dff5103f6346090e6280c8 # LQ
                        - e204b80c87be9497a8a6eaff48f72905 # LQ (Release Title)
                        - b8cd450cbfa689c0259a01d9e29ba3d6 # 3D
                        - bfd8eb01832d646a0a89c4deb46f8564 # Upscaled
                        - 0a3f082873eb454bde444150b70253cc # Extras
                        - 712d74cd88bceb883ee32f773656b1f5 # Sing-Along Versions
                        - a5d148168c4506b55cf53984107c396e # Hi10P
                        - cae4ca30163749b891686f95532519bd # AV1
                        - 839bea857ed2c0a8e084f3cbdbd65ecb # x265 (no HDR/DV)

                        # Resolution
                        - 820b09bb9acbfde9c35c71e0e565dad8 # 1080p
                        - b2be17d608fc88818940cd1833b0b24c # 720p

                        # Streaming Services
                        - cc5e51a9e85a6296ceefe097a77f12f4 # BCORE
                        - 16622a6911d1ab5d5b8b713d5b0036d4 # CRiT
                        - 2a6039655313bf5dab1e43523b62c374 # MA
                      assign_scores_to:
                        - name: SQP-1 (1080p-2160p)
            '';
        };

        services.my.recyclarr = {
          dashboard = {
            enable = false;
          };
          monitor = {
            enable = false;
          };
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
                image = "ghcr.io/recyclarr/recyclarr:8.8.1";
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
