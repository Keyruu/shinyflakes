{ inputs, ... }:
{
  den.aspects.apps.zed = {
    homeManager =
      {
        pkgs,
        ...
      }:
      let
        pkgs-stable = import inputs.nixpkgs-stable { inherit (pkgs.stdenv.hostPlatform) system; };
      in
      {
        programs.zed-editor = {
          enable = true;
          package = pkgs-stable.zed-editor;
        };
      };
  };
}
