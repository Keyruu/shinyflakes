{
  config,
  flake,
  lib,
  pkgs,
  ...
}:
let
  my = config.services.my.seerr;
  inherit (config.virtualisation.quadlet) containers;
  inherit (flake.lib) quadlet;
  settings = "${my.stack.path}/config/settings.json";

  # OIDC has no env var or UI support on the preview tag — the provider block
  # lives in seerr-owned mutable settings.json, so merge it in on every start
  mergeOidc = pkgs.writeShellApplication {
    name = "seerr-merge-oidc";
    runtimeInputs = [
      pkgs.jq
      pkgs.coreutils
    ];
    text = ''
      # first boot: seerr creates settings.json during setup, merge applies on next restart
      [ -f ${settings} ] || exit 0
      jq -s '.[0] * .[1]' ${settings} ${config.sops.templates."seerr-oidc.json".path} > ${settings}.new
      # ExecStartPre runs as root; seerr (node, uid 1000) must keep write access
      chown --reference=${settings} ${settings}.new
      mv ${settings}.new ${settings}
    '';
  };
in
{
  sops.secrets.seerrClientSecret = { };

  sops.templates."seerr-oidc.json" = {
    restartUnits = [ (quadlet.service containers.seerr) ];
    content = builtins.toJSON {
      oidc.providers = [
        {
          slug = "authelia";
          name = "Authelia";
          issuerUrl = "https://auth.peeraten.net";
          clientId = "seerr";
          clientSecret = config.sops.placeholder.seerrClientSecret;
          newUserLogin = true;
        }
      ];
    };
  };

  services.my.seerr =
    let
      domain = "requests.peeraten.net";
    in
    {
      zfs = true;
      port = 5055;
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
        # image runs as node (uid 1000)
        directories = [
          {
            path = "config";
            owner = "1000";
            group = "1000";
          }
        ];
        security.enable = false;

        containers.seerr = {
          containerConfig = {
            # digest-pinned: preview-new-oidc is a moving tag (OIDC not in stable yet,
            # see https://github.com/seerr-team/seerr/discussions/2721)
            image = "ghcr.io/seerr-team/seerr:preview-new-oidc@sha256:6a2a160b878b98d079c8ee6933f58997bb26d68dbcbc789c1a559bc6955db60d";
            runInit = true;
            environments = {
              TZ = "Europe/Berlin";
            };
            volumes = [ "${my.stack.path}/config:/app/config" ];
            publishPorts = [
              "127.0.0.1:${toString my.port}:5055"
              "${config.services.mesh.ip}:${toString my.port}:5055"
            ];
            healthCmd = "wget --no-verbose --tries=1 --spider http://localhost:5055/api/v1/settings/public || exit 1";
            healthStartPeriod = "20s";
            healthTimeout = "3s";
            healthInterval = "15s";
            healthRetries = 3;
          };
          serviceConfig.ExecStartPre = [ (lib.getExe mergeOidc) ];
        };
      };
    };
}
