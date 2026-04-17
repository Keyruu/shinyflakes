{ config, flake, ... }:
let
  my = config.services.my.multi-scrobbler;
  inherit (config.virtualisation.quadlet) containers;
  inherit (flake.lib) quadlet;
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
    restartUnits = [ (quadlet.service containers.multi-scrobbler) ];
    owner = "multi-scrobbler";
    group = "multi-scrobbler";
    content = ''
      SPOTIFY_CLIENT_ID=${config.sops.placeholder.multiScrobblerSpotifyClientId}
      SPOTIFY_CLIENT_SECRET=${config.sops.placeholder.multiScrobblerSpotifyClientSecret}
      KOITO_USER=admin
      KOITO_TOKEN=${config.sops.placeholder.multiScrobblerKoitoToken}
      KOITO_URL=http://koito:4110
      LZENDPOINT_ENABLE=true
      LZE_TOKEN=${config.sops.placeholder.multiScrobblerListenBrainzToken}
      LASTFM_API_KEY=${config.sops.placeholder.multiScrobblerLastfmApiKey}
      LASTFM_SECRET=${config.sops.placeholder.multiScrobblerLastfmSharedSecret}
    '';
  };

  services.my.multi-scrobbler = {
    port = 9078;
    domain = "scrobble.keyruu.de";
    proxy.enable = false;
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
          image = "ghcr.io/foxxmd/multi-scrobbler:0.13.1";
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

      @protected not path /1*
      basic_auth @protected {
        lucas {$PASSWORD_HASH}
      }
      reverse_proxy http://127.0.0.1:${toString my.port}
    '';
  };
}
