{ ... }:
{
  den.aspects.workstation.fprintd = {
    nixos = { ... }: {
      services.fprintd.enable = true;
    };
  };
}
