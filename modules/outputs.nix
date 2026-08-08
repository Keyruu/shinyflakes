# Flake outputs bridge — wires `den` outputs into the flake so
# `nix build '.#packages.<system>.<pkg>'` keeps working after the
# blueprint package directory goes away.

{ inputs, den, ... }:
{
  imports = [ inputs.den.flakeOutputs.packages ];
  den.schema.flake-system.includes = [ ];
  # Package aspects register like:
  #   den.aspects.zfs-unlock.packages = { pkgs, ... }: { zfs-unlock = ...; };
  # and surface via `nix build '.#packages.x86_64-linux.zfs-unlock'`.

  # Formatter — kept the same as the old nix/formatter.nix.
  flake.formatter.x86_64-linux = inputs.nixpkgs.legacyPackages.x86_64-linux.nixfmt-tree;
}
