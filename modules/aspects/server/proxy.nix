# Bespoke reverse-proxy routes for prime — coraza waf rules with custom
# directives on git.keyruu.de, geoblock + websocket splits on tv/hass,
# authelia forward-auth on status.peeraten.net, and plain cloudflare-only
# reverse proxies for the rest.
#
# These routes are too custom for the public-proxy quirk consumer to
# generate (no data field for waf directives / geoblock). Simple routes
# (traccar, requests, etc.) also exist in this file to keep prime's
# public surface in one place — public-proxy quirk consumer would also
# generate them, both end up at the same vhost key (deep merge).
#
# Replaces nix/hosts/prime/modules/proxy.nix.
{ lib, ... }:
let
  mentat = "100.67.0.2";
  karaokeDomain = "einfachnextlevel.karaoke.keyruu.de";
in
{
  den.aspects.server.proxy = {
    nixos = {
      services.caddy.virtualHosts = {
        # simple cloudflare-only reverse proxies — duplicate of what
        # public-proxy quirk consumer would generate; deep-merge keeps
        # this vhost entry intact (the quirk entry has compatible fields).
        "traccar.peeraten.net" = {
          extraConfig = ''
            import coraza-waf
            import cloudflare-only
            reverse_proxy http://${mentat}:5785
          '';
        };
        "owntracks.peeraten.net" = {
          extraConfig = ''
            import coraza-waf
            import cloudflare-only
            reverse_proxy http://${mentat}:5144
          '';
        };
        "requests.peeraten.net" = {
          extraConfig = ''
            import coraza-waf
            import cloudflare-only
            reverse_proxy http://${mentat}:5055
          '';
        };
        "calendar.peeraten.net" = {
          extraConfig = ''
            import coraza-waf
            import cloudflare-only
            reverse_proxy http://${mentat}:5232
          '';
        };
        "files.keyruu.de" = {
          extraConfig = ''
            import coraza-waf
            import cloudflare-only
            reverse_proxy http://${mentat}:3210
          '';
        };
        "cache.keyruu.de" = {
          extraConfig = ''
            import coraza-waf
            import cloudflare-only
            reverse_proxy http://${mentat}:7384
          '';
        };
        "s3.keyruu.de" = {
          extraConfig = ''
            import coraza-waf
            import cloudflare-only
            reverse_proxy http://${mentat}:3900
          '';
        };
        "garage.keyruu.de" = {
          extraConfig = ''
            import coraza-waf
            import cloudflare-only
            reverse_proxy http://${mentat}:3902
          '';
        };
        "${karaokeDomain}" = {
          extraConfig = ''
            import coraza-waf
            reverse_proxy http://${mentat}:5555
          '';
        };

        # gatus runs on mentat; authelia forward_auth + waf enforced here on prime
        "status.peeraten.net" = {
          extraConfig = ''
            import coraza-waf
            import cloudflare-only

            forward_auth 127.0.0.1:8010 {
              uri /api/authz/forward-auth
              copy_headers Remote-User Remote-Groups Remote-Name Remote-Email
            }

            reverse_proxy http://${mentat}:8044
          '';
        };

        # forgejo with bespoke coraza waf directives — runner API + git
        # operations + gitea/forgejo API + issue content paths bypass
        # specific CRS rules that false-positive on those request shapes.
        "git.keyruu.de" = {
          extraConfig = ''
            coraza_waf {
              load_owasp_crs
              directives `
                SecRuleEngine On

                # turn off waf for the forgejo runner service as there are too many false positives
                SecRule REQUEST_URI "@beginsWith /api/actions/runner.v1.RunnerService/" \
                  "id:1000,\
                  phase:1,\
                  pass,\
                  nolog,\
                  ctl:ruleEngine=Off"

                # disable rules for Git operations (.git/ paths)
                SecRule REQUEST_URI "@rx \.git/" \
                  "id:1001,\
                  phase:1,\
                  pass,\
                  nolog,\
                  ctl:ruleRemoveById=930130,\
                  ctl:ruleRemoveById=920270,\
                  ctl:ruleRemoveById=920450,\
                  ctl:ruleRemoveById=921150,\
                  ctl:ruleRemoveById=942100,\
                  ctl:ruleRemoveById=942540"

                # disable rules for Gitea/Forgejo API (issues, PRs, markdown bodies from Renovate)
                SecRule REQUEST_URI "@beginsWith /api/v1/" \
                  "id:1002,\
                  phase:1,\
                  pass,\
                  nolog,\
                  ctl:ruleRemoveById=932140,\
                  ctl:ruleRemoveById=932230,\
                  ctl:ruleRemoveById=932235,\
                  ctl:ruleRemoveById=932250,\
                  ctl:ruleRemoveById=932260,\
                  ctl:ruleRemoveById=941160,\
                  ctl:ruleRemoveById=941180"

                # disable rules for issue content paths
                SecRule REQUEST_URI "@rx /.*/issues/.*/content" \
                  "id:1003,\
                  phase:1,\
                  pass,\
                  nolog,\
                  ctl:ruleRemoveById=932140,\
                  ctl:ruleRemoveById=932230,\
                  ctl:ruleRemoveById=932235,\
                  ctl:ruleRemoveById=932250,\
                  ctl:ruleRemoveById=932260,\
                  ctl:ruleRemoveById=941160,\
                  ctl:ruleRemoveById=941180"

                Include @coraza.conf-recommended
                Include @crs-setup.conf.example
                Include @owasp_crs/*.conf

                SecRuleRemoveById 949110
                SecRuleRemoveById 932370
                SecRuleRemoveById 911100
                SecRuleRemoveById 920420
                SecRuleRemoveById 200002
                SecRuleRemoveById 200003
              `
            }
            import cloudflare-only
            reverse_proxy http://${mentat}:3004 {
              header_up X-Real-Ip {remote_host}
            }
          '';
        };

        # geoblock instead of cloudflare-only: streams must not go through CF.
        # WAF only on API routes — streaming/image/download paths bypass it
        # (CRS false-positives on segment/range requests + CPU per stream),
        # /socket bypasses bc coraza can't handle the websocket upgrade
        "tv.peeraten.net" = {
          extraConfig = ''
            import geoblock-de
            handle @geo-allowed {
              @bulk path_regexp (?i)^/(emby/)?(videos|audio|items/[^/]+/(download|images)|socket)
              handle @bulk {
                reverse_proxy http://${mentat}:8096
              }
              handle {
                import coraza-waf
                reverse_proxy http://${mentat}:8096
              }
            }
            handle {
              respond 403
            }
          '';
        };

        # websocket path is split out bc coraza can't handle the upgrade
        "hass.peeraten.net" = {
          extraConfig = ''
            import geoblock-de
            handle @geo-allowed {
              import websocket /api/websocket http://${mentat}:8123

              handle {
                import coraza-waf
                import cloudflare-only
                reverse_proxy http://${mentat}:8123 {
                  header_up X-Forwarded-For {http.request.header.CF-Connecting-IP}
                }
              }
            }
            handle {
              respond 403
            }
          '';
        };
      };
    };
  };
}
