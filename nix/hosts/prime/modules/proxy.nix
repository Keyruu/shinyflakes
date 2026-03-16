{ lib, config, ... }:
let
  mentat = config.services.mesh.people.lucas.devices.mentat.ip;
  proxyHosts = {
    "traccar.peeraten.net" = {
      proxyHost = mentat;
      proxyPort = 5785;
      cloudflare = true;
    };
    "owntracks.peeraten.net" = {
      proxyHost = mentat;
      proxyPort = 5144;
      cloudflare = true;
    };
    "map.peeraten.net" = {
      proxyHost = mentat;
      proxyPort = 3001;
      cloudflare = true;
    };
    "calendar.peeraten.net" = {
      proxyHost = mentat;
      proxyPort = 5232;
      cloudflare = true;
    };
    "files.keyruu.de" = {
      proxyHost = mentat;
      proxyPort = 3210;
      cloudflare = true;
    };
    "s3.keyruu.de" = {
      proxyHost = mentat;
      proxyPort = 3900;
      cloudflare = true;
    };
    "garage.keyruu.de" = {
      proxyHost = mentat;
      proxyPort = 3902;
      cloudflare = true;
    };
    "29112025karaoke.keyruu.de" = {
      proxyHost = mentat;
      proxyPort = 5555;
      cloudflare = false;
    };
  };

  mkProxyHost =
    {
      proxyHost,
      proxyPort,
      cloudflare,
    }:
    {
      extraConfig = ''
        import coraza-waf
        ${lib.optionalString cloudflare "import cloudflare-only"}
        reverse_proxy http://${proxyHost}:${toString proxyPort}
      '';
    };
in
{
  services.caddy.virtualHosts = (lib.mapAttrs (_: mkProxyHost) proxyHosts) // {
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

    # websocket path is split out bc coraza can't handle the upgrade
    "hass.peeraten.net" = {
      extraConfig = ''
        import websocket /api/websocket http://${mentat}:8123

        handle {
          import coraza-waf
          import cloudflare-only
          reverse_proxy http://${mentat}:8123 {
            header_up X-Forwarded-For {http.request.header.CF-Connecting-IP}
          }
        }
      '';
    };
  };
}
