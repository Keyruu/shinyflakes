{
  inputs,
  perSystem,
  pkgs,
  ...
}:
let
  tofunix-lib = inputs.tofunix.lib {
    inherit pkgs;
    inherit (pkgs) lib;
  };

  tofunix = tofunix-lib.mkCliAio {
    plugins = [
      perSystem.self.tf-cloudflare
      perSystem.self.tf-hcloud
    ];
    moduleConfig = ../terraform/main.nix;
  };
in
# after a flake update the opentofu derivation changes, which invalidates
# the h1: hashes in .terraform.lock.hcl and the provider symlinks in
# .terraform/providers/ (they point into a garbage-collected store path).
# since providers are already pinned by nix (exact version + sha256), the
# lock file adds no value so we delete stale state and reinit providers
# each time so tofu always sees providers matching the current nix closure.
pkgs.writeShellApplication {
  name = "tofunix";
  runtimeInputs = [ ];
  text = # bash
    ''
      rm -f .terraform.lock.hcl
      rm -rf .terraform/providers .terraform/plugin_path

      ${tofunix}/bin/tofunix init -input=false -backend=false > /dev/null 2>&1

      exec ${tofunix}/bin/tofunix "$@"
    '';
}
