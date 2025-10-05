{
  inputs,
  flake,
  config,
  pkgs,
  lib,
  ...
}:
{
  imports = [
    flake.modules.darwin.brew
    flake.modules.darwin.darwin
    flake.modules.nixos.build-machines

    # Import local modules
    ./modules
  ];

  # Set the primary user name
  user.name = "lucas.rott";

  # Set hostname
  networking.hostName = "PCL2022020701";
  networking.computerName = "PCL2022020701";

  # List packages installed in system profile. To search by name, run:
  # $ nix-env -qaP | grep wget
  environment.systemPackages = [
    pkgs.vim
    pkgs.nixd
    pkgs.fish
  ];

  nix.package = pkgs.nixVersions.latest;

  users.knownUsers = [ config.user.name ];
  users.users."${config.user.name}" = {
    shell = pkgs.fish;
    uid = 880220207;
  };

  # documentation.man.enable = false;

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
        config.user.name
        "@admin"
      ];
      sandbox = false;
    };
  };

  # Create /etc/zshrc that loads the nix-darwin environment.
  programs.fish.enable = true;

  # Set Git commit hash for darwin-version.
  system.configurationRevision = flake.rev or flake.dirtyRev or null;

  # Used for backwards compatibility, please read the changelog before changing.
  # $ darwin-rebuild changelog
  system.stateVersion = 4;

  # The platform the configuration will be used on.
  nixpkgs.hostPlatform = "aarch64-darwin";
}
