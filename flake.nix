{
  description = "Keyruu's shinyflakes";

  nixConfig = {
    extra-substituters = [
      # "https://attic.joinemm.dev/cache?priority=41"
      "https://nixpkgs.cachix.org"
      "https://nix-community.cachix.org"
      "https://anyrun.cachix.org"
    ];
    extra-trusted-public-keys = [
      "cache:U/hdZXmAW51DPCRFSU5EVlr5EFn2aafUOK63LACEeyo="
      "nixpkgs.cachix.org-1:q91R6hxbwFvDqTSDKwDAV4T5PxqXGxswD8vhONFMeOE="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "anyrun.cachix.org-1:pqBobmOjI7nKlsUMV25u9QHa9btJK65/C8vnO3p346s="
    ];
  };

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs-darwin.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    sops-nix.url = "github:Mic92/sops-nix";

    nixos-hardware.url = "github:nixos/nixos-hardware";

    nixvirt = {
      url = "https://flakehub.com/f/AshleyYakeley/NixVirt/*.tar.gz";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    quadlet-nix = {
      url = "github:SEIAROTg/quadlet-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs-darwin";
    };

    nix-darwin = {
      url = "github:LnL7/nix-darwin/master";
      inputs.nixpkgs.follows = "nixpkgs-darwin";
    };

    nixvim = {
      url = "github:nix-community/nixvim";
      inputs = {
        nixpkgs.follows = "nixpkgs-darwin";
      };
    };

    nur = {
      url = "github:nix-community/NUR";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    hyprland.url = "git+https://github.com/hyprwm/Hyprland?submodules=1";
    stylix.url = "github:danth/stylix";
    apple-fonts.url = "github:Lyndeno/apple-fonts.nix";
    zen-browser.url = "git+https://git.sr.ht/~canasta/zen-browser-flake/";
    nixcord.url = "github:kaylorben/nixcord";
    hyprswitch.url = "github:h3rmt/hyprswitch/release";
    iio-hyprland.url = "github:JeanSchoeller/iio-hyprland";

    spicetify-nix = {
      url = "github:Gerg-L/spicetify-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    hyprgrass = {
      url = "github:horriblename/hyprgrass";
      inputs.hyprland.follows = "hyprland"; # IMPORTANT
    };

    anyrun = {
      url = "github:anyrun-org/anyrun";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixpkgs-fprintd-fix.url = "github:pineapplehunter/nixpkgs/9f9f51f10007131b1d7c94a2072264b0c1e0f52d";
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
      nixvirt,
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
            nixvirt.nixosModules.default
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
