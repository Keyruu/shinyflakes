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

  # jq * is a deep merge: objects merge recursively, arrays/scalars are replaced.
  mergeSettings = pkgs.writeShellApplication {
    name = "seerr-merge-settings";
    runtimeInputs = [
      pkgs.jq
      pkgs.coreutils
    ];
    text = ''
      # first boot: seerr creates settings.json during setup, merge applies on next restart
      [ -f ${settings} ] || exit 0
      jq -s '.[0] * .[1]' ${settings} ${
        config.sops.templates."seerr-settings.json".path
      } > ${settings}.new
      # ExecStartPre runs as root; seerr (node, uid 1000) must keep write access
      chown --reference=${settings} ${settings}.new
      mv ${settings}.new ${settings}
    '';
  };
in
{
  sops.secrets = {
    seerrClientSecret = { };
    seerrGotifyToken = { };
    jellyfinKey = { };
    sonarrKey = { };
    radarrKey = { };
  };

  sops.templates."seerr-settings.json" = {
    restartUnits = [ (quadlet.service containers.seerr) ];
    content = builtins.toJSON {
      main = {
        # providers are only surfaced on the login page when oidcLogin is set
        oidcLogin = true;
        localLogin = false;
        mediaServerLogin = false;
        applicationTitle = "Requests";
        applicationUrl = "https://requests.peeraten.net";
      };
      # real client IPs behind the nginx/prime proxies
      network.trustProxy = true;
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
      # partial merge: name/serverId/libraries stay live. mesh IP instead of
      # tv.peeraten.net - the public domain is DE-geoblocked, VPN exits CH (403s)
      jellyfin = {
        ip = config.services.mesh.ip;
        port = 8096;
        useSsl = false;
        externalHostname = "https://tv.peeraten.net";
        apiKey = config.sops.placeholder.jellyfinKey;
      };
      sonarr = [
        {
          id = 0;
          name = "Sonarr";
          hostname = "localhost";
          port = 8989;
          apiKey = config.sops.placeholder.sonarrKey;
          useSsl = false;
          baseUrl = "";
          externalUrl = "https://sonarr.lab.keyruu.de";
          activeProfileId = 9;
          activeProfileName = "WEB (1080p-2160p)";
          activeDirectory = "/data/Series";
          animeSeriesType = "anime";
          activeAnimeProfileId = 7;
          activeAnimeProfileName = "Remux-1080p - Anime";
          activeAnimeDirectory = "/data/Anime";
          tags = [ ];
          animeTags = [ ];
          is4k = false;
          isDefault = true;
          enableSeasonFolders = false;
          syncEnabled = true;
          preventSearch = false;
          tagRequests = true;
          monitorNewItems = "all";
        }
      ];
      radarr = [
        {
          id = 0;
          name = "Radarr";
          hostname = "localhost";
          port = 7878;
          apiKey = config.sops.placeholder.radarrKey;
          useSsl = false;
          activeProfileId = 9;
          activeProfileName = "SQP-1 (1080p-2160p)";
          externalUrl = "https://radarr.lab.keyruu.de";
          activeDirectory = "/data/Movies";
          is4k = false;
          minimumAvailability = "released";
          tags = [ ];
          isDefault = true;
          syncEnabled = true;
          preventSearch = false;
          tagRequests = true;
        }
      ];
      notifications.agents.gotify = {
        enabled = true;
        types = 4062;
        options = {
          url = "https://notify.keyruu.de";
          token = config.sops.placeholder.seerrGotifyToken;
          priority = 0;
          locale = "en";
        };
      };
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
            # gluetun netns like the other media containers: sonarr/radarr via localhost,
            # jellyfin via its mesh publish (tv.peeraten.net is DE-geoblocked, VPN exits CH)
            networks = [ "media-gluetun.container" ];
            healthCmd = "wget --no-verbose --tries=1 --spider http://localhost:5055/api/v1/settings/public || exit 1";
            healthStartPeriod = "20s";
            healthTimeout = "3s";
            healthInterval = "15s";
            healthRetries = 3;
          };
          unitConfig = {
            After = [ containers.media-gluetun.ref ];
            Requires = [ containers.media-gluetun.ref ];
          };
          serviceConfig.ExecStartPre = [ (lib.getExe mergeSettings) ];
        };
      };
    };

  virtualisation.quadlet.containers.media-gluetun.containerConfig = {
    # ports live on the netns owner; mesh publish is what prime's proxy targets
    publishPorts = [
      "127.0.0.1:${toString my.port}:5055"
      "${config.services.mesh.ip}:${toString my.port}:5055"
    ];
    # let netns containers reach mesh-published services (seerr → jellyfin)
    # without leaving through the VPN
    environments.FIREWALL_OUTBOUND_SUBNETS = config.services.mesh.subnet;
  };
}
