{
  inputs,
  outputs,
  pkgs,
  lib,
  modules,
  username,
  ...
}:
{
  imports = lib.flatten [
    (with modules; [
      brew
      darwin
      build-machines
    ])
  ];

  # List packages installed in system profile. To search by name, run:
  # $ nix-env -qaP | grep wget
  environment.systemPackages = [
    pkgs.vim
    pkgs.nixd
    pkgs.fish
  ];

  nix.package = pkgs.nixVersions.latest;

  users.knownUsers = [ username ];
  users.users."${username}" = {
    shell = pkgs.fish;
    uid = 880220207;
  };

  documentation.man.enable = false;

  # nix.package = pkgs.nix;
  nixpkgs.config.allowUnfree = true;

  # Necessary for using flakes on this system.
  nix = {
    nixPath = [ "nixpkgs=${inputs.nixpkgs-darwin}" ];
    gc = {
      automatic = lib.mkDefault true;
      options = lib.mkDefault "--delete-older-than 7d";
    };

    settings = {
      experimental-features = [
        "nix-command"
        "flakes"
      ];
      trusted-users = [
        "lucas.rott"
        "@admin"
      ];
      sandbox = false;
    };
  };

  # Create /etc/zshrc that loads the nix-darwin environment.
  programs.fish.enable = true;

  # Set Git commit hash for darwin-version.
  system.configurationRevision = outputs.rev or outputs.dirtyRev or null;

  # Used for backwards compatibility, please read the changelog before changing.
  # $ darwin-rebuild changelog
  system.stateVersion = 4;

  # The platform the configuration will be used on.
  nixpkgs.hostPlatform = "aarch64-darwin";
}
