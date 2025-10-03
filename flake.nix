{
  description = "Keyruu's shinyflakes";

  nixConfig = {
    extra-substituters = [
      "https://cache.nixos.org/"
      "https://vicinae.cachix.org"
    ];
    extra-trusted-public-keys = [
      "cache:U/hdZXmAW51DPCRFSU5EVlr5EFn2aafUOK63LACEeyo="
      "vicinae.cachix.org-1:1kDrfienkGHPYbkpNj1mWTr7Fm1+zcenzgTizIcI3oc="
    ];
  };

  inputs = {
    nixpkgs.url = "git+https://github.com/NixOS/nixpkgs?shallow=1&ref=nixos-unstable";
    nixpkgs-darwin.url = "git+https://github.com/NixOS/nixpkgs?shallow=1&ref=nixpkgs-unstable";
    nixpkgs-small.url = "git+https://github.com/NixOS/nixpkgs?shallow=1&ref=nixos-unstable-small";

    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-index-database = {
      url = "github:nix-community/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixos-hardware.url = "github:nixos/nixos-hardware";

    quadlet-nix.url = "github:SEIAROTg/quadlet-nix";

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
      url = "github:danth/stylix/75411fe2b90f67bfb4a2ad9cc3b1379758b64dbb";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    zen-browser = {
      url = "git+https://git.sr.ht/~canasta/zen-browser-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    iio-sway = {
      url = "github:tbaumann/iio-sway";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-gaming = {
      url = "github:fufexan/nix-gaming";
      inputs = {
        nixpkgs.follows = "nixpkgs";
      };
    };

    sherlock = {
      url = "github:Skxxtz/sherlock";
      inputs = {
        nixpkgs.follows = "nixpkgs";
      };
    };

    vicinae.url = "github:vicinaehq/vicinae";

    sirberus = {
      url = "github:Keyruu/sirberus";
      inputs.nixpkgs.follows = "nixpkgs";
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
      stylix,
      vicinae,
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
