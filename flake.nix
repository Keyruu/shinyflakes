{
  description = "Keyruu's shinyflakes";

  nixConfig = {
    extra-substituters = [
      "https://cache.nixos.org/"
      "https://cache.lix.systems"
    ];
    extra-trusted-public-keys = [
      "cache:U/hdZXmAW51DPCRFSU5EVlr5EFn2aafUOK63LACEeyo="
      "cache.lix.systems:aBnZUw8zA7H35Cz2RyKFVs3H4PlGTLawyY5KRbvJR8o="
    ];
  };

  inputs = {
    nixpkgs.url = "git+https://github.com/NixOS/nixpkgs?shallow=1&ref=nixos-unstable";
    nixpkgs-darwin.url = "git+https://github.com/NixOS/nixpkgs?shallow=1&ref=nixpkgs-unstable";
    nixpkgs-small.url = "git+https://github.com/NixOS/nixpkgs?shallow=1&ref=nixos-unstable-small";

    lix-module = {
      url = "https://git.lix.systems/lix-project/nixos-module/archive/2.93.0.tar.gz";
      inputs.nixpkgs.follows = "nixpkgs";
    };

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

    # nixcord = {
    #   url = "github:kaylorben/nixcord";
    #   inputs.nixpkgs.follows = "nixpkgs";
    # };

    iio-hyprland = {
      url = "github:JeanSchoeller/iio-hyprland";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    iio-sway = {
      url = "github:tbaumann/iio-sway";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    hyprgrass = {
      url = "git+https://github.com/horriblename/hyprgrass?shallow=1&ref=main";
      inputs.hyprland.follows = "hyprland"; # IMPORTANT
    };

    hy3 = {
      url = "github:outfoxxed/hy3?ref=hl0.49.0";
      inputs.hyprland.follows = "hyprland";
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
      lix-module,
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
