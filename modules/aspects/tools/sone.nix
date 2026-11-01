{ ... }:
{
  den.aspects.tools.sone = {
    homeManager =
      {
        pkgs,
        ...
      }:
      {
        home.packages = [ pkgs.sone ];
      };
  };
}
