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
tofunix-lib.mkCliAio {
  plugins = [
    (tofunix-lib.mkOpentofuProvider {
      owner = "cloudflare";
      repo = "cloudflare";
      version = "5.15.0";
      hash = "sha256-OVmE5zPRp+kEj7zGxxVu2bcNA2gDdj4m5DgAZckQW2k=";
    })
    (tofunix-lib.mkOpentofuProvider {
      owner = "hetznercloud";
      repo = "hcloud";
      version = "1.57.0";
      hash = "sha256-vdw+oskc7ASOnEuCyijl/racJeO4hc7AN6APsUwmvzY=";
    })
  ];
  moduleConfig = ../terraform/main.nix;
}
