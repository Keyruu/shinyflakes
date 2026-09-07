# Multi-scrobbler — lastfm/liblistenbrainz/spotify scrobble aggregator.
# Single-container stack on prime; joins the koito stack's network so
# the container can reach koito at http://koito:4110.
# Replaces nix/hosts/prime/modules/stacks/multi-scrobbler.nix.
{ ... }:
{
  den.aspects.services.multi-scrobbler = {
    nixos = { config, ... }:
      let
        my = config.services.my.multi-scrobbler;
      in
      {
      users = {
        groups.multi-scrobbler.gid = 1001;
        users = {
          multi-scrobbler = {
            isSystemUser = true;
            uid = 1001;
            group = "multi-scrobbler";
          };
        };
      };

      sops.secrets = {
        multiScrobblerSpotifyClientId = { };
        multiScrobblerSpotifyClientSecret = { };
        multiScrobblerKoitoToken = { };
        multiScrobblerListenBrainzToken = { };
        multiScrobblerLastfmApiKey = { };
        multiScrobblerLastfmSharedSecret = { };
      };

      sops.templates."multi-scrobbler.env" = {
        restartUnits = [ "multi-scrobbler.service" ];
        owner = "multi-scrobbler";
        group = "multi-scrobbler";
        content = ''
          SPOTIFY_CLIENT_ID=${config.sops.placeholder.multiScrobblerSpotifyClientId}
          SPOTIFY_CLIENT_SECRET=${config.sops.placeholder.multiScrobblerSpotifyClientSecret}
          KOITO_USER=admin
          KOITO_TOKEN=${config.sops.placeholder.multiScrobblerKoitoToken}
          KOITO_URL=http://koito:4110
          LZE_ENABLE=true
          LZE_TOKEN=${config.sops.placeholder.multiScrobblerListenBrainzToken}
          LASTFM_API_KEY=${config.sops.placeholder.multiScrobblerLastfmApiKey}
          LASTFM_SECRET=${config.sops.placeholder.multiScrobblerLastfmSharedSecret}
          SOURCE_LASTFM_ID=lastfm-source
          SOURCE_LASTFM_NAME=Last.fm
          SOURCE_LASTFM_ENABLE=true
          SOURCE_LASTFM_API_KEY=${config.sops.placeholder.multiScrobblerLastfmApiKey}
          SOURCE_LASTFM_SECRET=${config.sops.placeholder.multiScrobblerLastfmSharedSecret}
        '';
      };

      services.my.multi-scrobbler = {
        port = 9078;
        domain = "scrobble.keyruu.de";
        proxy.enable = false;
        monitor.enable = false;
        stack = {
          enable = true;
          user = {
            enable = true;
            uid = 1001;
            gid = 1001;
          };
          directories = [
            {
              path = "config";
              mode = "0750";
              owner = "multi-scrobbler";
              group = "multi-scrobbler";
            }
          ];

          containers.multi-scrobbler = {
            containerConfig = {
              image = "ghcr.io/foxxmd/multi-scrobbler:0.15.0";
              publishPorts = [ "127.0.0.1:${toString my.port}:9078" ];
              volumes = [ "${my.stack.path}/config:/config" ];
              environments = {
                TZ = "Europe/Berlin";
                BASE_URL = "https://${my.domain}";
                PUID = "1001";
                PGID = "1001";
              };
              environmentFiles = [ config.sops.templates."multi-scrobbler.env".path ];
              networks = [ config.virtualisation.quadlet.networks.koito.ref ];
            };
          };
        };
      };

      services.caddy.virtualHosts."${my.domain}" = {
        extraConfig = ''
          import coraza-waf
          import cloudflare-only

          # ListenBrainz endpoint is its own bearer-token auth (LZE_TOKEN);
          # skip forward_auth so player submissions work without browser cookies.
          handle /1* {
            reverse_proxy http://127.0.0.1:${toString my.port}
          }

          handle {
            forward_auth 127.0.0.1:8010 {
              uri /api/authz/forward-auth?policy=multi_scrobbler_access
              copy_headers Remote-User Remote-Groups Remote-Name Remote-Email
            }

            reverse_proxy http://127.0.0.1:${toString my.port}
          }
        '';
      };
    };
  };
}
