# Static webpages served by prime — homepage + buymeaspezi.
# Each vhost root is the package from a sibling flake input
# (homepage repo, buymeaspezi repo). Replaces nix/hosts/prime/modules/webpages.nix.
#
# self'.X = this flake's packages; inputs'.X = flake input's outputs.
# homepage + buymeaspezi are flake inputs with their own packages.
{ ... }:
{
  den.aspects.server.webpages = {
    nixos = { inputs', ... }: {
      services.caddy.virtualHosts = {
        "keyruu.de" = {
          extraConfig = ''
            import coraza-waf
            import cloudflare-only

            header {
              -Last-Modified
            }
            encode
            root ${inputs'.homepage.packages.default}
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
            root ${inputs'.buymeaspezi.packages.default}
            file_server {
              etag_file_extensions .etag
            }
          '';
        };
      };
    };
  };
}
