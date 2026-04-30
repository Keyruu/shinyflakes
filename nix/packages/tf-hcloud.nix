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

  # renovate: datasource=terraform-provider depName=hetznercloud/hcloud
  version = "1.62.0";
in
tofunix-lib.mkOpentofuProvider {
  owner = "hetznercloud";
  repo = "hcloud";
  inherit version;
  hash = "sha256-fD8dDJgZFvlrBFDcvvxiKTJXpd+7pmUZqDuE5xOEyGs=";
}
