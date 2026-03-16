{
  config,
  lib,
  ...
}:
{
  config.services.caddy.extraConfig = ''
    (coraza-waf) {
      coraza_waf {
        load_owasp_crs
        directives `
          SecRuleEngine On

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
    }

    (websocket) {
      handle {args[0]} {
        @websockets {
          header_regexp Connection Upgrade
          header        Upgrade websocket
        }
        reverse_proxy @websockets {args[1]}
      }
    }
  '';
}
