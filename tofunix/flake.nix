{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    tofunix.url = "github:Keyruu/tofunix?dir=lib";
  };

  outputs =
    inputs@{
      flake-parts,
      ...
    }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];

      perSystem =
        {
          pkgs,
          lib,
          ...
        }:
        let
          tofunix-lib = inputs.tofunix.lib { inherit pkgs lib; };
        in
        {
          packages.tofunix = tofunix-lib.mkCliAio {
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
            moduleConfig = ./main.nix; # nix module, so either a path, an attrset, a function etc.
          };

          devShells.default = pkgs.mkShell {
            packages = [
              pkgs.opentofu
              pkgs.terraform-docs
              pkgs.jq
            ];

            shellHook = ''
              echo "🚀 Tofunix development environment"
              echo ""
              echo "Example commands:"
              echo "  nix run .#tofunix -- init    - Initialize OpenTofu"
              echo "  nix run .#tofunix -- plan    - Run tofu plan"
              echo "  nix run .#tofunix -- apply   - Run tofu apply"
              echo "  nix run .#tofunix -- destroy - Run tofu destroy"
              echo ""
            '';
          };

          formatter = pkgs.nixfmt-rfc-style;
        };
    };
}
