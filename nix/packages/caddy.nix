{ pkgs, ... }:
let
  # renovate: datasource=go depName=github.com/corazawaf/coraza-caddy/v2
  corazaCaddyVersion = "v2.5.0";
  # renovate: datasource=go depName=github.com/greenpau/caddy-security
  caddySecurityVersion = "v1.1.62";
in
pkgs.caddy.withPlugins {
  plugins = [
    "github.com/corazawaf/coraza-caddy/v2@${corazaCaddyVersion}"
    "github.com/greenpau/caddy-security@${caddySecurityVersion}"
  ];
  hash = "sha256-Mhp5V5NXYeSTF2/lI1ceNLaeJ9dUYE1HScAOAqSaBjU=";
}
