{ inputs, lib, ... }:
let
  overlay = final: prev: {
    zellij = final.callPackage ../packages/zellij.nix { inherit inputs; };
  };
in
{
  den.default.nixos.nixpkgs.overlays = [ overlay ];
  den.default.homeManager.nixpkgs.overlays = [ overlay ];

  perSystem = { system, ... }: {
    _module.args.pkgs = import inputs.nixpkgs {
      inherit system;
      overlays = [ overlay ];
    };
  };
}
