{
  description = "Keyruu's Hati Flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "nixpkgs";

    sops-nix.url = "github:Mic92/sops-nix";
  };

  outputs = inputs @ {
    self,
    nixpkgs,
    disko,
    sops-nix,
    ...
  }: let
    inherit (self) outputs;
    hostname = "hati";
    specialArgs = {
      inherit inputs outputs hostname;
    };
  in {
    # Build darwin flake using:
    # $ darwin-rebuild build --flake .#stern
    nixosConfigurations."${hostname}" = nixpkgs.lib.nixosSystem {
      inherit specialArgs;
      system = "x86_64-linux";
      modules = [
        disko.nixosModules.disko
        sops-nix.nixosModules.sops
        ./modules
      ];
    };
  };
}
