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
  version = "1.65.0";
in
tofunix-lib.mkOpentofuProvider {
  owner = "hetznercloud";
  repo = "hcloud";
  inherit version;
  hash = "sha256-YfgfU3Sz6KlCBmVIJ2zpT7MOMOROLha9PT6AmHiM8TE=";
}
