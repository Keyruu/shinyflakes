{ ... }:
{
  den.aspects.tools.file-explorer = {
    nixos = { pkgs, ... }: {
      environment.systemPackages = [ pkgs.nautilus ];
      services.udisks2.enable = true;
      services.gvfs.enable = true;
    };
  };
}
