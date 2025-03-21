  # To edit use your text editor application, for example Nano
{ pkgs, ... }: {
  podman = pkgs.callPackage ./podman.nix { };
}
