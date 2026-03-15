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
in
tofunix-lib.mkOpentofuProvider {
  owner = "cloudflare";
  repo = "cloudflare";
  version = "5.15.0";
  hash = "sha256-Yvi7bgpdj9Fl48rtolxkGdW9VhiJjiG7DdZlCQJnm/w=";
}
