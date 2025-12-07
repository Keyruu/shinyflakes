{ pkgs, ... }:
{
  programs.nvf.settings.vim = {
    utility = {
      direnv.enable = true;
      preview.glow.enable = true;
      snacks-nvim.enable = true;
      yanky-nvim.enable = true;
      yazi-nvim.enable = true;
    };
    extraPlugins = with pkgs.vimPlugins; {
      kanagawa-nvim = {
        package = kanagawa-nvim;
        setup = # lua
          ''
            require('kanagawa').setup({
              transparent = false,
              terminalColors = false,
              colors = {
                palette = {
                  sumiInk0 = "#0c0e0f",
                  sumiInk1 = "#0e1011",
                  sumiInk2 = "#101213",
                  sumiInk3 = "#121415",
                  sumiInk4 = "#141617",
                  sumiInk5 = "#161819",
                  oldWhite = "#dae1e6",
                },
                theme = { wave = {}, lotus = {}, dragon = {}, all = {} },
              },
              overrides = function(colors)
                return {}
              end,
              theme = "wave",
              background = {
                dark = "wave",
                light = "lotus",
              },
            })
            vim.cmd.colorscheme('kanagawa')
          '';
      };
    };

    startPlugins = with pkgs.vimPlugins; [
      plenary-nvim
    ];
  };
}
