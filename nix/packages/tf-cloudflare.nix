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
  version = "5.21.0";
in
tofunix-lib.mkOpentofuProvider {
  owner = "cloudflare";
  repo = "cloudflare";
  inherit version;
  hash = "sha256-K3xZXqdxraedqi7plHi5jDTY/6yiI1o7dNTdt/sNnBs=";
}
