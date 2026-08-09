{ inputs, ... }:
{
  den.aspects.apps.spotify = {
    homeManager =
      { inputs', ... }:
      {
        imports = [
          inputs.spicetify-nix.homeManagerModules.default
        ];

        programs.spicetify =
          let
            spicePkgs = inputs'.spicetify-nix.legacyPackages;
          in
          {
            enable = true;

            enabledExtensions = with spicePkgs.extensions; [
              adblock
              hidePodcasts
              shuffle # shuffle+ (special characters are sanitized out of extension names)
              keyboardShortcut
            ];

            theme = spicePkgs.themes.text;
            # colorScheme = "mocha";
          };
      };
  };
}
