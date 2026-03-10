{
  config,
  pkgs,
  flake,
  ...
}:
let
  my = config.services.my.koito;
  inherit (config.virtualisation.quadlet) containers;
  inherit (flake.lib) quadlet;
in
{
  sops.secrets.koitoDbPassword = { };

  sops.templates = {
    "koito-main.env" = {
      restartUnits = [ (quadlet.service containers.koito-main) ];
      content = ''
        KOITO_DATABASE_URL=postgres://postgres:${config.sops.placeholder.koitoDbPassword}@db:5432/koitodb
        KOITO_ALLOWED_HOSTS=${my.domain},koito:4110
        KOITO_CORS_ALLOWED_ORIGINS=https://keyruu.de,http://localhost:4321
        KOITO_ENABLE_FULL_IMAGE_CACHE=true
      '';
    };
    "koito-db.env" = {
      restartUnits = [ (quadlet.service containers.koito-db) ];
      content = ''
        POSTGRES_DB=koitodb
        POSTGRES_USER=postgres
        POSTGRES_PASSWORD=${config.sops.placeholder.koitoDbPassword}
      '';
    };
  };

  services.my.koito = {
    port = 4110;
    domain = "fm.keyruu.de";
    proxy = {
      enable = true;
      server = "caddy";
      whitelist.enable = true;
    };
    backup.enable = true;
    stack = {
      enable = true;
      directories = [
        "data"
        {
          path = "db";
          owner = "999";
          group = "999";
        }
      ];
      network.enable = true;

      containers = {
        db = {
          containerConfig = {
            image = "postgres:16";
            volumes = [ "${my.stack.path}/db:/var/lib/postgresql/data" ];
            environmentFiles = [ config.sops.templates."koito-db.env".path ];
            healthCmd = "pg_isready -U postgres -d koitodb";
            healthInterval = "3s";
            healthTimeout = "5s";
            healthRetries = 5;
            healthStartPeriod = "10s";
            networkAliases = [ "db" ];
          };
        };

        main = {
          containerConfig =
            let
              inherit (config.virtualisation.quadlet) builds;
            in
            {
              image = builds.koito.ref;
              publishPorts = [ "127.0.0.1:${toString my.port}:4110" ];
              volumes = [ "${my.stack.path}/data:/etc/koito" ];
              environmentFiles = [ config.sops.templates."koito-main.env".path ];
              networkAliases = [ "koito" ];
            };
          dependsOn = [ "db" ];
        };
      };
    };
  };

  virtualisation.quadlet.builds.koito.buildConfig =
    let
      src = fetchGit {
        url = "https://github.com/Keyruu/Koito.git";
        rev = "fee7fb811c8b34cb70ef7f376907c41bbb4044b4";
      };
    in
    {
      workdir = "${src}";
      file = "${src}/Dockerfile";
    };
}
