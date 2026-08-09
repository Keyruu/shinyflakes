{ ... }:
{
  den.aspects.workstation.blueman = {
    nixos = { pkgs, ... }: {
      services.blueman.enable = true;
    };
  };
}
