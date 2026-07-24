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
  version = "1.67.0";
in
tofunix-lib.mkOpentofuProvider {
  owner = "hetznercloud";
  repo = "hcloud";
  inherit version;
  hash = "sha256-KXNkSZbPfEhu78SeCqaWhiyp7XEfzIjNHaj93I9aI8I=";
}
