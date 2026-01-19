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
            Include @coraza.conf-recommended
            Include @crs-setup.conf.example
            Include @owasp_crs/*.conf

            # remove REQUEST-949-BLOCKING-EVALUATION, REQUEST-932-APPLICATION-ATTACK-RCE.conf, REQUEST-911-METHOD-ENFORCEMENT.conf bc of a lot of false positives
            SecRuleRemoveById 949110
            SecRuleRemoveById 932370
            SecRuleRemoveById 911100
            # somehow this blocks some http protocol, idfk 
            SecRuleRemoveById 920420

            # fix home assistant issues with WAF
            SecRule REQUEST_URI "@beginsWith /api/websocket" "id:999001,phase:1,pass,nolog,ctl:ruleEngine=Off"
            SecRule REQUEST_URI "@beginsWith /auth" "id:999002,phase:1,pass,nolog,ctl:ruleEngine=Off"
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
