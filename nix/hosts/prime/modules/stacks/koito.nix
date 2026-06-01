{
  config,
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
      restartUnits = [ (quadlet.service containers.koito) ];
      content = ''
        KOITO_SQLITE_ENABLED=true
        KOITO_CORS_ALLOWED_ORIGINS=https://keyruu.de,http://localhost:4321
        KOITO_ENABLE_FULL_IMAGE_CACHE=true
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
      ];
      network.enable = true;

      containers = {
        koito = {
          containerConfig =
            # let
            #   inherit (config.virtualisation.quadlet) builds;
            # in
            {
              image = "gabehf/koito:v0.3.2";
              publishPorts = [ "127.0.0.1:${toString my.port}:4110" ];
              volumes = [ "${my.stack.path}/data:/etc/koito" ];
              environmentFiles = [ config.sops.templates."koito-main.env".path ];
            };
        };
      };
    };
  };

  # virtualisation.quadlet.builds.koito.buildConfig =
  #   let
  #     src = fetchGit {
  #       url = "https://github.com/Keyruu/Koito.git";
  #       rev = "fee7fb811c8b34cb70ef7f376907c41bbb4044b4";
  #     };
  #   in
  #   {
  #     workdir = "${src}";
  #     file = "${src}/Dockerfile";
  #   };
}
