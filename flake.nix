{
  description = "Keyruu's shinyflakes";

  nixConfig = {
    extra-substituters = [
      "https://attic.joinemm.dev/cache?priority=41"
      "https://deploy-rs.cachix.org?priority=44"
    ];
    extra-trusted-public-keys = [
      "cache:U/hdZXmAW51DPCRFSU5EVlr5EFn2aafUOK63LACEeyo="
      "deploy-rs.cachix.org-1:xfNobmiwF/vzvK1gpfediPwpdIP0rpDV2rYqx40zdSI="
    ];
  };

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs-darwin.url = "github:NixOS/nixpkgs/8809585e6937d0b07fc066792c8c9abf9c3fe5c4";

    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    sops-nix.url = "github:Mic92/sops-nix";

    nixos-hardware.url = "github:nixos/nixos-hardware";

    deploy-rs = {
      url = "github:serokell/deploy-rs";
      inputs = {
        nixpkgs.follows = "nixpkgs";
      };
    };

    quadlet-nix = {
      url = "github:SEIAROTg/quadlet-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    kanata = {
      url = "github:alexandru0-dev/kanata-flake";
      inputs.nixpkgs.follows = "nixpkgs-darwin";
    };

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

  outputs =
    inputs@{
      self,
      nix-darwin,
      disko,
      sops-nix,
      nixpkgs,
      home-manager,
      deploy-rs,
      quadlet-nix,
      ...
    }:
    let
      specialArgs = {
        inherit inputs;
        inherit (self) outputs;
        modules = import ./modules;
      };
      x86 = {
        sleipnir = {
          hostname = "sleipnir";
          profiles.system = {
            sshUser = "root";
            user = "root";
            path = deploy-rs.lib.x86_64-linux.activate.nixos self.nixosConfigurations.sleipnir;
            fastConnection = true;
            remoteBuild = true;
          };
        };
        hati = {
          hostname = "hati";
          profiles.system = {
            sshUser = "root";
            user = "root";
            path = deploy-rs.lib.x86_64-linux.activate.nixos self.nixosConfigurations.hati;
            fastConnection = true;
            remoteBuild = true;
          };
        };
      };

      aarch64 = {
        garm = {
          hostname = "192.168.100.5";
          profiles.system = {
            sshUser = "root";
            user = "root";
            path = deploy-rs.lib.aarch64-linux.activate.nixos self.nixosConfigurations.garm;
            fastConnection = true;
            remoteBuild = false;
          };
        };
      };
    in
    {
      deploy.nodes = x86 // aarch64;
      checks = {
        x86_64-linux = deploy-rs.lib.x86_64-linux.deployChecks { nodes = x86; };
        aarch64-linux = deploy-rs.lib.aarch64-linux.deployChecks { nodes = aarch64; };
      };

      nixosConfigurations.hati =
        let
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
                users."${args.username}" = import ./home;
              };
            }
          ];
        };
    };
}
