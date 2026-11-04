{ inputs, lib, ... }:
let
  # kitty 0.50.0 is not in nixpkgs yet, build it from the upstream tag
  kittyVersion = "0.50.0";

  overlay = final: prev: {
    zellij = final.callPackage ../packages/zellij.nix { inherit inputs; };

    kitty = prev.kitty.overrideAttrs (old: rec {
      version = kittyVersion;
      src = final.fetchFromGitHub {
        owner = "kovidgoyal";
        repo = "kitty";
        tag = "v${kittyVersion}";
        hash = "sha256-CSSjL931OLZ9wwz9E3rAfMcm+TpczVJzJh9MPfuKmVU=";
      };
      goModules =
        (final.buildGo126Module {
          pname = "kitty-go-modules";
          inherit version src;
          vendorHash = "sha256-Oo5ehjdq4HcTxZcKi/rwz8dDZYGxdSS8cqIkbdLBrb8=";
        }).goModules;
    });
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
