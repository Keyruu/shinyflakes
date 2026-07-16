{ pkgs, ... }:
let
  # renovate: datasource=github-releases depName=9p4/jellyfin-plugin-sso
  version = "v4.0.0.4";
in
pkgs.fetchzip {
  url = "https://github.com/9p4/jellyfin-plugin-sso/releases/download/${version}/sso-authentication_${pkgs.lib.removePrefix "v" version}.zip";
  stripRoot = false;
  hash = "sha256-MJTyE6CeVLk7mlugauJ/F6bpi1kYwNtzNmQeH3+CFeQ=";
}
