{ ... }:
{
  den.aspects.apps.neovim = {
    homeManager =
      { self', ... }:
      {
        programs.neovim = {
          enable = true;
          package = self'.packages.nvim;
        };
      };
  };
}
