{
  inputs,
  pkgs,
  ...
}:
let
  tofu = pkgs.opentofu.withPlugins (p: [
    p.cloudflare_cloudflare
    p.hetznercloud_hcloud
  ]);

  terraformConfiguration = inputs.terranix.lib.terranixConfiguration {
    inherit pkgs;
    modules = [ ../terraform ];
  };
in
# after a flake update the opentofu derivation changes, which invalidates
# the h1: hashes in .terraform.lock.hcl and the provider symlinks in
# .terraform/providers/ (they point into a garbage-collected store path).
# since providers are already pinned by nix, the lock file adds no value
# so we delete stale state and reinit providers each time so tofu always
# sees providers matching the current nix closure.
pkgs.writeShellApplication {
  name = "tf";
  runtimeInputs = [ tofu ];
  text = # bash
    ''
      cp -f ${terraformConfiguration} config.tf.json

      rm -f .terraform.lock.hcl
      rm -rf .terraform/providers .terraform/plugin_path

      tofu init -input=false -backend=false > /dev/null 2>&1

      exec tofu "$@"
    '';
}
