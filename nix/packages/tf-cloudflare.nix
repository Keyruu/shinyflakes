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
  version = "5.21.1";
in
tofunix-lib.mkOpentofuProvider {
  owner = "cloudflare";
  repo = "cloudflare";
  inherit version;
  hash = "sha256-MdU8wwnKqF8UM0YoRA+rTGPyx5Z3ct4mrf5ag3iLRvw=";
}
