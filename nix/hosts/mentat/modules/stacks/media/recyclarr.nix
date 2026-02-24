{ config, ... }:
let
  recyclarrPath = "/etc/stacks/recyclarr/config";
in
{
  users = {
    groups.recyclarr.gid = 1006;
    users = {
      recyclarr = {
        isSystemUser = true;
        uid = 1006;
        group = "recyclarr";
      };
    };
  };

  systemd.tmpfiles.rules = [
    "d ${recyclarrPath} 0755 recyclarr recyclarr"
  ];

  sops.templates."recyclarrConfig.yaml" = {
    restartUnits = [ "media-recyclarr.service" ];
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
              # Run `recyclarr list quality-profiles sonarr` to get these exact IDs!
              - trash_id: 20e0fc959f1f1704bed501f23bdae76f
                name: Remux-1080p - Anime
                reset_unmatched_scores:
                  enabled: true
                  
              - trash_id: d1498e7d189fbe6c7110ceaabb7473e6
                name: WEB-2160p
                reset_unmatched_scores:
                  enabled: true

            custom_formats:
              - trash_ids:
                  - 026d5aadd1a6b4e550b134cb6c72b3ca # Uncensored
                  - b2550eb333d27b75833e25b8c2557b38 # 10bit
                  - 418f50b10f1907201b6cfdf881f467b7 # Anime Dual Audio
                assign_scores_to:
                  - name: Remux-1080p - Anime

              - trash_ids:
                  - 32b367365729d530ca1c124a0b180c64 # Bad Dual Groups
                  - 9b27ab6498ec0f31a3353992e19434ca # DV (WEBDL)
                  - 82d40da2bc6923f41e14394075dd4b03 # No-RlsGroup
                assign_scores_to:
                  - name: WEB-2160p

              - trash_ids:
                  - ed51973a811f51985f14e2f6f290e47a # German DL (default -10000)
                assign_scores_to:
                  - name: Remux-1080p - Anime
                    score: 11000
                  - name: WEB-2160p
                    score: 11000

              - trash_ids:
                  - 8a9fcdbb445f2add0505926df3bb7b8a # German
                  - c5dd0fd675f85487ad5bdf97159180bd # German DL (undefined)
                  - 133589380b89f8f8394320901529bac1 # Not German or English
                  - da0f005f9c3edf34fc26e18dce8c6573 # German Remux Tier 01
                  - 6bc5ccd80a03e7abb8f556eecd174b73 # German Remux Tier 02
                  - 68be37323132b35cf333c81a2ac8fc16 # German Web Tier 01
                  - f51b96a50b0e6196cb69724b7833d837 # German Web Tier 02
                  - bda67c2c0aae257308a4723d92475b86 # German Web Tier 03
                  - c2eec878fa1989599c226ce4c287d6a7 # German Scene
                  - a6a6c33d057406aaad978a6902823c35 # German LQ
                  - 237eda4ef550a97da2c9d87b437e500b # German Microsized
                assign_scores_to:
                  - name: Remux-1080p - Anime
                  - name: WEB-2160p

        radarr:
          movies:
            base_url: http://localhost:7878
            api_key: ${config.sops.placeholder.radarrKey}

            quality_definition:
              type: movie

            quality_profiles:
              # SQP-1 (1080p) -> mapped to HD Bluray + WEB
              - trash_id: d1d67249d3890e49bc12e275d989a7e9
                name: SQP-1 (1080p)
                reset_unmatched_scores:
                  enabled: true
                min_format_score: 10
                
              # SQP-1 (2160p) -> mapped to UHD Bluray + WEB
              - trash_id: 64fb5f9858489bdac2af690e27c8f42f
                name: SQP-1 (2160p)
                reset_unmatched_scores:
                  enabled: true
                min_format_score: 10

            custom_formats:
              - trash_ids:
                  - dc98083864ea246d05a42df0d05f81cc # x265 (HD)
                assign_scores_to:
                  - name: SQP-1 (1080p)

              - trash_ids:
                  - f845be10da4f442654c13e1f2c3d6cd5 # German DL (default -10000)
                assign_scores_to:
                  - name: SQP-1 (1080p)
                    score: 11000
                  - name: SQP-1 (2160p)
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
                  - name: SQP-1 (1080p)
                  - name: SQP-1 (2160p)

              - trash_ids:
                  - 3bc8df3a71baaac60a31ef696ea72d36 # German 1080p Booster
                assign_scores_to:
                  - name: SQP-1 (1080p)

              - trash_ids:
                  - cc7b1e64e2513a6a271090cdfafaeb55 # German 2160p Booster
                assign_scores_to:
                  - name: SQP-1 (2160p)
      '';
  };

  virtualisation.quadlet.containers.media-recyclarr = {
    containerConfig = {
      image = "ghcr.io/recyclarr/recyclarr:8.3.0";
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
    serviceConfig = {
      Restart = "always";
    };
    unitConfig = {
      After = [ "media-gluetun.service" ];
      Requires = [ "media-gluetun.service" ];
    };
  };
}
