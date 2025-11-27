{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    terranix.url = "github:terranix/terranix";
  };

  outputs =
    {
      nixpkgs,
      terranix,
      ...
    }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};

      terraformConfig = terranix.lib.terranixConfiguration {
        inherit system;
        modules = [ ./main.nix ];
      };
    in
    {
      packages.${system}.default = terraformConfig;

      devShells.${system}.default = pkgs.mkShell {
        packages = [
          pkgs.opentofu
          pkgs.terraform-docs
          pkgs.terranix
        ];
      };

      apps.${system} = {
        show = {
          type = "app";
          program = toString (
            pkgs.writeShellScript "show-config" ''
              cat ${terraformConfig} | jq .
            ''
          );
        };

        plan = {
          type = "app";
          program = toString (
            pkgs.writeShellScript "tofu-plan" ''
              set -e
              rm -rf .terraform config.tf.json
              cp ${terraformConfig} config.tf.json
              ${pkgs.opentofu}/bin/tofu init
              ${pkgs.opentofu}/bin/tofu plan
            ''
          );
        };

        apply = {
          type = "app";
          program = toString (
            pkgs.writeShellScript "tofu-apply" ''
              set -e
              rm -rf .terraform config.tf.json
              cp ${terraformConfig} config.tf.json
              ${pkgs.opentofu}/bin/tofu init
              ${pkgs.opentofu}/bin/tofu apply
            ''
          );
        };
      };
    };
}
