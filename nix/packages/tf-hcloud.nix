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
  version = "1.66.1";
in
tofunix-lib.mkOpentofuProvider {
  owner = "hetznercloud";
  repo = "hcloud";
  inherit version;
  hash = "sha256-LMoatah1X2VA4gbIjHS8pKqUeBRpyznPdQHHayV9vO4=";
}
