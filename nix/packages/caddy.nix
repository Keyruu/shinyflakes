{ pkgs, ... }:
let
  # renovate: datasource=go depName=github.com/corazawaf/coraza-caddy/v2
  corazaCaddyVersion = "v2.2.0";
  # renovate: datasource=go depName=github.com/greenpau/caddy-security
  caddySecurityVersion = "v1.1.47";
in
pkgs.caddy.withPlugins {
  plugins = [
    "github.com/corazawaf/coraza-caddy/v2@${corazaCaddyVersion}"
    "github.com/greenpau/caddy-security@${caddySecurityVersion}"
  ];
  hash = "sha256-QUDBcTH/gKJwq+fkztLnO/hB78u4OYyLlD7VLYiwUEU=";
}
