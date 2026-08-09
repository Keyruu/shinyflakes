{ inputs, ... }:
{
  den.aspects.workstation.flatpak = {
    nixos = { ... }: {
      imports = [
        inputs.nix-flatpak.nixosModules.nix-flatpak
      ];
      services.flatpak = {
        enable = true;
        packages = [
          "io.kinvolk.Headlamp"
        ];
        uninstallUnmanaged = true;
      };
    };
  };
}