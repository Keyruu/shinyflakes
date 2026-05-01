{
  inputs,
  pkgs,
  ...
}:
let
  tofunix-lib = inputs.tofunix.lib {
    inherit pkgs;
    inherit (pkgs) lib;
  };

  # renovate: datasource=terraform-provider depName=cloudflare/cloudflare
  version = "5.19.1";
in
tofunix-lib.mkOpentofuProvider {
  owner = "cloudflare";
  repo = "cloudflare";
  inherit version;
  hash = "sha256-HCTxAhVbXrykDfPEpdl7kotejGnALH9INUqB1RjW1O8=";
}
