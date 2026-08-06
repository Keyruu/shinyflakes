{
  perSystem,
  flake,
  lib,
  ...
}:
let
  # build app list from every host's services.my. admin group auto-prepended so
  # admin sees every card.
  mkApp = cfg: {
    title = cfg.dashboard.title;
    description = cfg.dashboard.description;
    url = "https://${cfg.domain}";
    icon = cfg.dashboard.icon;
    newTab = cfg.dashboard.newTab;
    groups = lib.unique ([ "admin" ] ++ cfg.dashboard.groups);
  };

  apps = lib.concatMap
    (cfg: lib.optional (cfg.dashboard.enable && cfg.domain != null) (mkApp cfg))
    (lib.attrValues flake.allMyServices);
in
{
  services.caddy.virtualHosts."dash.peeraten.net" = {
    extraConfig = ''
      import coraza-waf
      import cloudflare-only

      forward_auth 127.0.0.1:8010 {
        uri /api/authz/forward-auth
        copy_headers Remote-User Remote-Groups Remote-Name Remote-Email
      }

      # templates injects {{.Req.Header.Get "Remote-Groups"}} etc. into served HTML
      templates
      encode
      header Cache-Control "no-store"
      root * ${perSystem.self.dashboard.override { inherit apps; }}
      file_server
    '';
  };
}