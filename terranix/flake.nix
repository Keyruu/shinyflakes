{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    terranix.url = "github:terranix/terranix";
    flake-parts.follows = "terranix/flake-parts";
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
          system,
          ...
        }:
        let
          terraformConfig = inputs.terranix.lib.terranixConfiguration {
            inherit system;
            modules = [ ./main.nix ];
          };

          mkTofuScript =
            name: extraArgs:
            pkgs.writeShellScript "tofu-${name}" ''
              set -euo pipefail

              ln -sfn ${terraformConfig} config.tf.json

              if [ ! -d .terraform ]; then
                echo "Initializing OpenTofu..."
                ${pkgs.opentofu}/bin/tofu init
              fi

              ${pkgs.opentofu}/bin/tofu ${extraArgs} "$@"
            '';
        in
        {
          packages.default = terraformConfig;

          devShells.default = pkgs.mkShell {
            packages = [
              pkgs.opentofu
              pkgs.terraform-docs
              pkgs.terranix
              pkgs.jq
            ];

            shellHook = ''
              echo "🚀 Terranix development environment"
              echo ""
              echo "Available commands:"
              echo "  nix run .#show    - Show generated config"
              echo "  nix run .#update  - Update the terranix config"
              echo "  nix run .#plan    - Run tofu plan"
              echo "  nix run .#apply   - Run tofu apply"
              echo "  nix run .#destroy - Run tofu destroy"
              echo "  nix run .#init    - Initialize OpenTofu"
              echo ""
              echo "Or use tofu commands directly after running 'nix run .#init'"
            '';
          };

          apps = {
            default = {
              type = "app";
              program = toString (mkTofuScript "plan" "plan");
            };

            show = {
              type = "app";
              program = toString (
                pkgs.writeShellScript "show-config" ''
                  ${pkgs.jq}/bin/jq . ${terraformConfig}
                ''
              );
            };

            update = {
              type = "app";
              program = toString (
                pkgs.writeShellScript "tofu-init" ''
                  set -euo pipefail
                  ln -sfn ${terraformConfig} config.tf.json
                ''
              );
            };

            init = {
              type = "app";
              program = toString (
                pkgs.writeShellScript "tofu-init" ''
                  set -euo pipefail
                  ln -sfn ${terraformConfig} config.tf.json
                  ${pkgs.opentofu}/bin/tofu init
                ''
              );
            };

            plan = {
              type = "app";
              program = toString (mkTofuScript "plan" "plan");
            };

            apply = {
              type = "app";
              program = toString (mkTofuScript "apply" "apply");
            };

            destroy = {
              type = "app";
              program = toString (mkTofuScript "destroy" "destroy");
            };
          };

          formatter = pkgs.nixfmt-rfc-style;
        };
    };
}
