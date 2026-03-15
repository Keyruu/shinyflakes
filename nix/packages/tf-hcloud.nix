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
  owner = "hetznercloud";
  repo = "hcloud";
  version = "1.57.0";
  hash = "sha256-x0qBzwP6tA42PuWJ1qleSBDYr48AP8khBW5fMMhs0ZQ=";
}
