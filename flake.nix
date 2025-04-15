{
  description = "Keyruu's shinyflakes";

  nixConfig = {
    extra-substituters = [
      # "https://attic.joinemm.dev/cache?priority=41"
      "https://nixpkgs.cachix.org"
      "https://nix-community.cachix.org"
    ];
    extra-trusted-public-keys = [
      "cache:U/hdZXmAW51DPCRFSU5EVlr5EFn2aafUOK63LACEeyo="
      "nixpkgs.cachix.org-1:q91R6hxbwFvDqTSDKwDAV4T5PxqXGxswD8vhONFMeOE="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
    ];
  };

  inputs = {
    nixpkgs.url = "git+https://github.com/NixOS/nixpkgs?shallow=1&ref=nixos-unstable";
    nixpkgs-darwin.url = "git+https://github.com/NixOS/nixpkgs?shallow=1&ref=nixpkgs-unstable";

    disko = {
      url = "git+https://github.com/nix-community/disko?shallow=1";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixos-hardware.url = "github:nixos/nixos-hardware";

    quadlet-nix = {
      url = "github:SEIAROTg/quadlet-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs-darwin";
    };

    nix-darwin = {
      url = "git+https://github.com/LnL7/nix-darwin?shallow=1&ref=master";
      inputs.nixpkgs.follows = "nixpkgs-darwin";
    };

    hyprland.url = "github:hyprwm/Hyprland";

    stylix = {
      url = "github:danth/stylix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    apple-fonts = {
      url = "github:Lyndeno/apple-fonts.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    zen-browser = {
      url = "git+https://git.sr.ht/~canasta/zen-browser-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixcord = {
      url = "github:kaylorben/nixcord";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    iio-hyprland = {
      url = "github:JeanSchoeller/iio-hyprland";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    spicetify-nix = {
      url = "github:Gerg-L/spicetify-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    hyprgrass = {
      url = "git+https://github.com/horriblename/hyprgrass?shallow=1&ref=main";
      inputs.hyprland.follows = "hyprland"; # IMPORTANT
    };
  };

  outputs =
    inputs@{
      self,
      nix-darwin,
      disko,
      sops-nix,
      nixpkgs,
      home-manager,
      quadlet-nix,
      nur,
      stylix,
      ...
    }:
    let
      specialArgs = {
        inherit inputs;
        inherit (self) outputs;
        modules = import ./modules;
      };
    in
    {
      nixosConfigurations.highwind =
        let
          args = specialArgs // {
            hostname = "highwind";
          };
        in
        nixpkgs.lib.nixosSystem {
          specialArgs = args;
          system = "x86_64-linux";
          modules = [
            disko.nixosModules.disko
            sops-nix.nixosModules.sops
            quadlet-nix.nixosModules.quadlet
            nur.modules.nixos.default
            ./hosts/highwind/configuration.nix
          ];
        };

      nixosConfigurations.sleipnir = nixpkgs.lib.nixosSystem {
        inherit specialArgs;
        system = "x86_64-linux";
        modules = [
          disko.nixosModules.disko
          sops-nix.nixosModules.sops
          quadlet-nix.nixosModules.quadlet
          ./hosts/sleipnir/configuration.nix
        ];
      };

      nixosConfigurations.garm = nixpkgs.lib.nixosSystem {
        inherit specialArgs;
        system = "aarch64-linux";
        modules = [
          disko.nixosModules.disko
          sops-nix.nixosModules.sops
          ./hosts/garm/configuration.nix
        ];
      };

      nixosConfigurations.thopter = 
        let
          args = specialArgs // {
            username = "lucas";
          };
        in
      nixpkgs.lib.nixosSystem {
      	specialArgs = args;
        system = "x86_64-linux";
        modules = [
          stylix.nixosModules.stylix
          ./hosts/thopter/configuration.nix

	  home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.extraSpecialArgs = args;
            home-manager.users.lucas = import ./home/linux;
          }
        ];
      };

      darwinConfigurations.stern =
        let
          args = specialArgs // {
            username = "lucas.rott";
            hostname = "PCL2022020701";
          };
        in
        nix-darwin.lib.darwinSystem {
          specialArgs = args;
          modules = [
            ./hosts/stern/configuration.nix

            # sops-nix.darwinModules.sops
            home-manager.darwinModules.home-manager
            {
              home-manager = {
                useGlobalPkgs = true;
                useUserPackages = true;
                extraSpecialArgs = args;
                users."${args.username}" = import ./home/mac;
              };
            }
          ];
        };
    };
}
