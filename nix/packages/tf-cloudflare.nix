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
  version = "5.18.0";
in
tofunix-lib.mkOpentofuProvider {
  owner = "cloudflare";
  repo = "cloudflare";
  inherit version;
  hash = "sha256-Yvi7bgpdj9Fl48rtolxkGdW9VhiJjiG7DdZlCQJnm/w=";
}
