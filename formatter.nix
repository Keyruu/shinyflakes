{ inputs, pkgs, ... }:
(inputs.treefmt-nix.lib.evalModule pkgs {
  projectRootFile = "flake.nix";
  programs.nixfmt.enable = true;
  programs.nixfmt.package = pkgs.nixfmt;

  programs.statix.enable = true;
  programs.deadnix.enable = true;

  settings.formatter.statix.priority = 1;
  settings.formatter.deadnix.priority = 2;
  settings.formatter.nixfmt.priority = 3;
}).config.build.wrapper
