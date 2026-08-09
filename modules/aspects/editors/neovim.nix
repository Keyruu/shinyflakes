{ ... }:
{
  den.aspects.editors.neovim = {
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
