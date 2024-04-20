{
  description = "Keyruu's Darwin Flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    # home-manager, used for managing user configuration
    home-manager = {
      url = "github:nix-community/home-manager/master";
      # The `follows` keyword in inputs is used for inheritance.
      # Here, `inputs.nixpkgs` of home-manager is kept consistent with the `inputs.nixpkgs` of the current flake,
      # to avoid problems caused by different versions of nixpkgs dependencies.
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-darwin.url = "github:LnL7/nix-darwin";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";

    nixvim = {
      url = "github:nix-community/nixvim";
      inputs = {
        nixpkgs.follows = "nixpkgs";
      };
    };
  };

  outputs = inputs @ { self, nix-darwin, nixpkgs, home-manager, ... }:
    let
      inherit (self) outputs;
      username = "lro";
      hostname = "stern";
      specialArgs = {
        inherit inputs outputs username hostname;
      };
    in
    {
      # Build darwin flake using:
      # $ darwin-rebuild build --flake .#stern
      darwinConfigurations."stern" = nix-darwin.lib.darwinSystem {
        inherit specialArgs;
        modules = [
          ./modules/configuration.nix
          ./modules/common.nix
          ./modules/brew.nix
          ./modules/system.nix

          # home manager
          home-manager.darwinModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;

            home-manager.extraSpecialArgs = specialArgs;
            home-manager.users."${username}" = import ./home;
          }
        ];
      };

      # Expose the package set, including overlays, for convenience.
      darwinPackages = self.darwinConfigurations."${hostname}".pkgs;
    };
}
