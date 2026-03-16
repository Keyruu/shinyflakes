{ perSystem, ... }:
{
  services = {
    caddy.virtualHosts = {
      "keyruu.de" = {
        extraConfig = ''
          import coraza-waf
          import cloudflare-only

          header {
            -Last-Modified
          }
          encode
          root ${perSystem.homepage.default}
          file_server {
            etag_file_extensions .etag
          }
        '';
      };
      "buymeaspezi.com" = {
        extraConfig = ''
          import coraza-waf
          import cloudflare-only

          header {
            -Last-Modified
          }
          encode
          root ${perSystem.buymeaspezi.default}
          file_server {
            etag_file_extensions .etag
          }
        '';
      };
    };
  };
}
