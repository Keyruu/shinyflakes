{ pkgs, ... }:
let
  # renovate: datasource=go depName=github.com/corazawaf/coraza-caddy/v2
  corazaCaddyVersion = "v2.5.0";
  # renovate: datasource=go depName=github.com/greenpau/caddy-security
  caddySecurityVersion = "v1.1.64";
in
pkgs.caddy.withPlugins {
  plugins = [
    "github.com/corazawaf/coraza-caddy/v2@${corazaCaddyVersion}"
    "github.com/greenpau/caddy-security@${caddySecurityVersion}"
  ];
  hash = "sha256-FYHWY2RGBGH7fc07MbCYRflAwzjNMu18Sqb+0xBtHGk=";
}
