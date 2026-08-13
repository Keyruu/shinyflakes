{ ... }:
{
  den.aspects.server.dashboard = {
    nixos =
      { dashboard, self', ... }:
      let
        apps = map (entry: {
          inherit (entry) title description url icon newTab groups;
        }) dashboard;
      in
      {
        services.caddy.virtualHosts."dash.peeraten.net".extraConfig = ''
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
          root * ${self'.packages.dashboard.override { inherit apps; }}
          file_server
        '';
      };
  };
}
