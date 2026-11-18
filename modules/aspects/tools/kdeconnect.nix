{ ... }:
{
  den.aspects.tools.kdeconnect = {
    nixos = {
      programs.kdeconnect.enable = true;
    };
    homeManager = {
      services.kdeconnect = {
        enable = true;
        indicator = true;
      };
    };
  };
}
