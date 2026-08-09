{ ... }:
{
  den.aspects.server.quadlet = {
    nixos = { ... }: {
      virtualisation.quadlet.autoEscape = true;
    };
  };
}