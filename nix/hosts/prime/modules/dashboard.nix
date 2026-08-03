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

      encode
      root * ${perSystem.self.dashboard}
      file_server
    '';
  };
}
