{
  description = "My flake";

  inputs = {
    # NixOS official package source, using the nixos-23.11 branch here
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager.url = "github:nix-community/home-manager/master";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = inputs @ { self, nixpkgs, home-manager, ... }: let
    inherit (self) outputs;
    user = "lucas";
    specialArgs = { inherit inputs outputs user; };
  in {
    # Please replace my-nixos with your hostname
    nixosConfigurations.nixos = nixpkgs.lib.nixosSystem {
      inherit specialArgs;
      system = "aarch64-linux";
      modules = [
        # Import the previous configuration.nix we used,
        # so the old configuration file still takes effect
        ./modules/users.nix
        ./configuration.nix
        ./modules/fonts.nix
        ./modules/common.nix
        ./modules/system.nix
 #       ./modules/networking.nix

        home-manager.nixosModules.home-manager 
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;

            home-manager.extraSpecialArgs = inputs;
            home-manager.users.lucas = import ./home;
          }
      ];
    };
  };
}
