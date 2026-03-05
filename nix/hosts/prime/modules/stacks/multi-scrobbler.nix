{ config, flake, ... }:
let
  stackPath = "/etc/stacks/multi-scrobbler";
  domain = "scrobble.keyruu.de";
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

  systemd.tmpfiles.rules = [
    "d ${stackPath}/config 0755 multi-scrobbler multi-scrobbler"
  ];

  sops.secrets = {
    multiScrobblerSpotifyClientId = { };
    multiScrobblerSpotifyClientSecret = { };
    multiScrobblerKoitoToken = { };
    multiScrobblerListenBrainzToken = { };
    multiScrobblerLastfmApiKey = { };
    multiScrobblerLastfmSharedSecret = { };
  };

  sops.templates = {
    "multi-scrobbler.env" = {
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
  };

  virtualisation.quadlet.containers =
    let
      inherit (config.virtualisation.quadlet) networks;
    in
    {
      multi-scrobbler = {
        containerConfig = {
          image = "ghcr.io/foxxmd/multi-scrobbler:0.11.5";
          publishPorts = [ "127.0.0.1:9078:9078" ];
          volumes = [ "${stackPath}/config:/config" ];
          environments = {
            TZ = "Europe/Berlin";
            BASE_URL = "https://${domain}";
            PUID = "1001";
            PGID = "1001";
          };
          environmentFiles = [ config.sops.templates."multi-scrobbler.env".path ];
          networks = [ networks.koito.ref ];
        };
        serviceConfig = {
          Restart = "always";
        };
      };
    };

  services = {
    caddy.virtualHostsWithDefaults = {
      "${domain}" = {
        extraConfig = ''
          import cloudflare-only

          @protected not path /1*
          basic_auth @protected {
            lucas {$PASSWORD_HASH}
          }
          reverse_proxy http://127.0.0.1:9078
        '';
      };
    };
  };
}
