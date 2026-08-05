{
  perSystem,
  ...
}:
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
      root * ${perSystem.self.dashboard}
      file_server
    '';
  };
}
