{ inputs, ... }:
{
  den.aspects.apps.nix-index-database = {
    homeManager =
      { ... }:
      {
        imports = [
          inputs.nix-index-database.homeModules.nix-index
        ];

        programs.nix-index = {
          enable = true;
          enableFishIntegration = true;
        };
        programs.nix-index-database.comma.enable = true;
      };
  };
}
