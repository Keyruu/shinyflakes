{ pkgs, ... }:
let
  # renovate: datasource=go depName=github.com/corazawaf/coraza-caddy/v2
  corazaCaddyVersion = "v2.5.0";
  # renovate: datasource=go depName=github.com/greenpau/caddy-security
  caddySecurityVersion = "v1.1.64";
  # renovate: datasource=go depName=github.com/porech/caddy-maxmind-geolocation
  caddyMaxmindVersion = "v1.0.3";
in
pkgs.caddy.withPlugins {
  plugins = [
    "github.com/corazawaf/coraza-caddy/v2@${corazaCaddyVersion}"
    "github.com/greenpau/caddy-security@${caddySecurityVersion}"
    "github.com/porech/caddy-maxmind-geolocation@${caddyMaxmindVersion}"
  ];
  hash = "sha256-nZ03CyB2g7RoqkU9+sD/dcB73aTtTEzQCb2t+vKZ7ck=";
}
