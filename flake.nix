{
  description = "Keyruu's shinyflakes";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs-darwin.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    disko= {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    sops-nix.url = "github:Mic92/sops-nix";

    home-manager = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs-darwin";
    };

    nix-darwin = {
      url = "github:LnL7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs-darwin";
    };

    nixvim = {
      url = "github:nix-community/nixvim";
      inputs = {
        nixpkgs.follows = "nixpkgs-darwin";
      };
    };
  };
  
  outputs = inputs @ {
    self,
    nix-darwin,
    disko,
    sops-nix,
    nixpkgs,
    home-manager,
    ...
  }: let
    specialArgs = {
      inherit inputs;
      inherit (self) outputs;
      modules = import ./modules;
    };
  in {
    nixosConfigurations.hati = let 
      args = specialArgs // {
        hostname = "hati";
      };
    in
      nixpkgs.lib.nixosSystem {
        specialArgs = args;
        system = "x86_64-linux";
        modules = [
          disko.nixosModules.disko
          sops-nix.nixosModules.sops
          ./hosts/hati/configuration.nix
        ];
      };

    darwinConfigurations.stern = let
      args =
        specialArgs
        // {
          username = "lro";
          hostname = "stern";
        };
    in 
      nix-darwin.lib.darwinSystem {
        specialArgs = args;
        modules = [
          ./hosts/stern/configuration.nix

          home-manager.darwinModules.home-manager
          {
            home-manager = {
              useGlobalPkgs = true;
              useUserPackages = true;
              extraSpecialArgs = args;
              users."${args.username}" = import ./home;
            };
          }
        ];
      };
    

    # Expose the package set, including overlays, for convenience.
    darwinPackages = self.darwinConfigurations."stern".pkgs;
  };
}

