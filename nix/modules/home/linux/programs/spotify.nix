{
  pkgs,
  inputs,
  perSystem,
  ...
}:
{
  imports = [
    inputs.spicetify-nix.homeManagerModules.default
  ];

  home.packages = with pkgs; [
    spotify-qt
    spotify-player
    librespot
    # spotify
  ];

  programs.spicetify =
    let
      spicePkgs = perSystem.spicetify-nix;
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
}
