{
  description = "Keyruu's shinyflakes";

  nixConfig = {
    extra-substituters = [
      # "https://attic.joinemm.dev/cache?priority=41"
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

    nixvirt = {
      url = "https://flakehub.com/f/AshleyYakeley/NixVirt/*.tar.gz";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    deploy-rs = {
      url = "github:serokell/deploy-rs";
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
      nixvirt,
      ...
    }:
    let
      specialArgs = {
        inherit inputs;
        inherit (self) outputs;
        modules = import ./modules;
      };

      # x86
      system = "x86_64-linux";
      pkgs = import nixpkgs { inherit system; };
      deployPkgs = import nixpkgs {
        inherit system;
        overlays = [
          deploy-rs.overlay # or deploy-rs.overlays.default
          (self: super: { deploy-rs = { inherit (pkgs) deploy-rs; lib = super.deploy-rs.lib; }; })
        ];
      };
      x86 = {
        sleipnir = {
          hostname = "sleipnir";
          profiles.system = {
            sshUser = "root";
            user = "root";
            path = deployPkgs.deploy-rs.lib.activate.nixos self.nixosConfigurations.sleipnir;
            fastConnection = true;
            remoteBuild = true;
            magicRollback = false;
            autoRollback = false;
          };
        };
        highwind = {
          hostname = "192.168.100.7";
          profiles.system = {
            sshUser = "root";
            user = "root";
            path = deployPkgs.deploy-rs.lib.activate.nixos self.nixosConfigurations.highwind;
            fastConnection = true;
            remoteBuild = true;
            magicRollback = false;
            autoRollback = false;
          };
        };
      };

      # aarch64
      system-aarch = "aarch64-linux";
      pkgs-aarch = import nixpkgs { system = system-aarch; };
      deployPkgs-aarch = import nixpkgs {
        system = system-aarch;
        overlays = [
          deploy-rs.overlay # or deploy-rs.overlays.default
          (self: super: {
            deploy-rs = { 
              pkgs = pkgs-aarch;
              inherit (pkgs-aarch) deploy-rs; 
              lib = super.deploy-rs.lib; 
            }; 
          })
        ];
      };
      aarch64 = {
        garm = {
          hostname = "192.168.100.5";
          profiles.system = {
            sshUser = "root";
            user = "root";
            path = deployPkgs-aarch.deploy-rs.lib.activate.nixos self.nixosConfigurations.garm;
            fastConnection = true;
            remoteBuild = false;
            magicRollback = false;
            autoRollback = false;
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
