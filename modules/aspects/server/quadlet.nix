{ ... }:
{
  den.aspects.quadlet = {
    nixos = { ... }: {
      virtualisation.quadlet.autoEscape = true;
    };
  };
}