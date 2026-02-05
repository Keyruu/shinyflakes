{ inputs, ... }:
{
  imports = [
    inputs.nix-flatpak.nixosModules.nix-flatpak
  ];
  services.flatpak = {
    enable = true;
    packages = [
      "io.kinvolk.Headlamp"
      "com.stremio.Stremio"
      "io.github.alyraffauf.Switchyard"
    ];
    uninstallUnmanaged = true;
  };
}
