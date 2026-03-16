{
  lib,
  config,
  options,
  ...
}:
let
  cfg = config.services.caddy;
  vhostType = options.services.caddy.virtualHosts.type;
in
{
  options = {
    services.caddy.virtualHostsWithDefaults = lib.mkOption {
      type = vhostType;
      description = ''
        Virtual hosts that will automatically get the default settings
        defined in `services.caddy.virtualHostDefaults`.
      '';
      default = { };
    };

    services.caddy.virtualHostDefaults = lib.mkOption {
      type = lib.types.str;
      description = "Extra Caddy configuration that will be appended to every vhost.";
      default = ''
        coraza_waf {
          load_owasp_crs
          directives `
            SecRuleEngine On

            # turn off waf for the forgejo runner service as there are too many cases of false positives
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

            # disable SSRF and RCE rules for /api/track (legitimate localhost referrers, blog URL paths)
            SecRule REQUEST_URI "@beginsWith /api/track" \
              "id:1004,\
              phase:1,\
              pass,\
              nolog,\
              ctl:ruleRemoveById=932260,\
              ctl:ruleRemoveById=934110"


            Include @coraza.conf-recommended
            Include @crs-setup.conf.example
            Include @owasp_crs/*.conf

            # NOTE: remove REQUEST-949-BLOCKING-EVALUATION, REQUEST-932-APPLICATION-ATTACK-RCE.conf, REQUEST-911-METHOD-ENFORCEMENT.conf bc of a lot of false positives
            SecRuleRemoveById 949110
            SecRuleRemoveById 932370
            SecRuleRemoveById 911100
            # NOTE: somehow this blocks some http protocol, idfk 
            SecRuleRemoveById 920420
            # NOTE: remove multipart body parsing failures (bufio: buffer full on large uploads)
            SecRuleRemoveById 200002
            SecRuleRemoveById 200003
          `
        }
      '';
    };
  };

  config =
    let
      mkMerge =
        host:
        host
        // {
          extraConfig = ''
            ${cfg.virtualHostDefaults}
            ${host.extraConfig}
          '';
        };
    in
    {
      services.caddy.virtualHosts = lib.mapAttrs (
        _name: mkMerge
      ) config.services.caddy.virtualHostsWithDefaults;
    };
}
