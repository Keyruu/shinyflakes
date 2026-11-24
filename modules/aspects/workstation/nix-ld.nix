{ ... }:
{
  # Run prebuilt binaries: uv-managed Python and manylinux wheels (cad/OCP for text-to-cad)
  den.aspects.workstation.nix-ld = {
    nixos =
      { pkgs, ... }:
      {
        programs.nix-ld = {
          enable = true;
          libraries = with pkgs; [
            expat
            fontconfig
            freetype
            libGL
            libx11
            libxext
            libxrender
            libxi
          ];
        };
      };
  };
}
