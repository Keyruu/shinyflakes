{ inputs, ... }:
{
  perSystem = { system, ... }: {
    _module.args.pkgs = import inputs.nixpkgs {
      inherit system;
      overlays = [
        (final: prev: {
          zellij = inputs.zellij.packages.${system}.default;
        })
      ];
    };
  };
}
