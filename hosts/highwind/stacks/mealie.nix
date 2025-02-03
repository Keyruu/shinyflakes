{pkgs, ...}: let
  dir = "stacks/mealie";
in
  {
    environment.etc."${dir}/compose.yaml".text =
      /*
      yaml
      */
      ''
        version: "3.1"
        networks:
          nginx:
            external: true
        services:
          mealie:
            container_name: mealie
            image: hkotel/mealie:v0.5.6
            restart: always
            labels:
              - diun.enable=false
            # networks:
            #   - nginx
            environment:
              PUID: 1000
              PGID: 1000
              TZ: Europe/Berlin
              # Default Recipe Settings
              RECIPE_PUBLIC: "true"
              RECIPE_SHOW_NUTRITION: "true"
              RECIPE_SHOW_ASSETS: "true"
              RECIPE_LANDSCAPE_VIEW: "true"
              RECIPE_DISABLE_COMMENTS: "false"
              RECIPE_DISABLE_AMOUNT: "false"
              # Gunicorn
              # WEB_CONCURRENCY: 2
              # WORKERS_PER_CORE: 0.5
              # MAX_WORKERS: 8
            volumes:
              - ./data/:/app/data
      '';

    systemd.services.mealie = {
      wantedBy = ["multi-user.target"];
      after = ["docker.service" "docker.socket"];
      path = [pkgs.docker];
      script = ''
        docker compose -f /etc/${dir}/compose.yaml up
      '';
      restartTriggers = [
        "/etc/${dir}/compose.yaml"
      ];
    };
  }
