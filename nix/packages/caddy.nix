{ pkgs, ... }:
let
  # renovate: datasource=go depName=github.com/corazawaf/coraza-caddy/v2
  corazaCaddyVersion = "v2.4.0";
  # renovate: datasource=go depName=github.com/greenpau/caddy-security
  caddySecurityVersion = "v1.1.50";
in
pkgs.caddy.withPlugins {
  plugins = [
    "github.com/corazawaf/coraza-caddy/v2@${corazaCaddyVersion}"
    "github.com/greenpau/caddy-security@${caddySecurityVersion}"
  ];
  hash = "sha256-PdEJ1F6F7ilDtG2zcMccYd3ZrqLzzBfCbeO+Y8YnR/M=";
}
