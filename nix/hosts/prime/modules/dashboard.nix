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

      # forward_auth populates Remote-Groups on the request; mirror it as a
      # response header so the JS can read it without a separate API call.
      # CORS exposes it cross-origin too in case the dashboard is ever embedded.
      header {
        Access-Control-Expose-Headers "X-User-Groups, X-User-Name"
        X-User-Groups "{http.request.header.Remote-Groups}"
        X-User-Name "{http.request.header.Remote-Name}"
      }

      encode
      root * ${perSystem.self.dashboard}
      file_server
    '';
  };
}
