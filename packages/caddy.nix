{ pkgs, ... }:
let
  # renovate: datasource=go depName=github.com/corazawaf/coraza-caddy/v2
  corazaCaddyVersion = "v2.6.1";
  # renovate: datasource=go depName=github.com/greenpau/caddy-security
  caddySecurityVersion = "v1.2.2";
  # renovate: datasource=go depName=github.com/porech/caddy-maxmind-geolocation
  caddyMaxmindVersion = "v1.0.3";
in
pkgs.caddy.withPlugins {
  plugins = [
    "github.com/corazawaf/coraza-caddy/v2@${corazaCaddyVersion}"
    "github.com/greenpau/caddy-security@${caddySecurityVersion}"
    "github.com/porech/caddy-maxmind-geolocation@${caddyMaxmindVersion}"
  ];
  hash = "sha256-kih56o9EDAIY7TNAr+WjOLYEl+tShlhIMASKXUDbS9o=";
}
