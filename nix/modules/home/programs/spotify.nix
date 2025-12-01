{
  config,
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
    librespot
    # spotify
  ];

  services.spotifyd = {
    enable = true;
  };

  programs.spotify-player = {
    enable = true;
    settings = {
      client_id = "2725ee3a3a7c48eda79c7162853183f2";
    };
  };

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
