{ perSystem, ... }:
{
  services = {
    caddy.virtualHostsWithDefaults = {
      "keyruu.de" = {
        extraConfig = ''
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
    };
  };
}
