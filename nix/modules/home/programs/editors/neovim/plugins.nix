{ pkgs, ... }:
{
  programs.nvf.settings.vim = {
    extraPlugins = with pkgs.vimPlugins; {
      yazi-nvim = {
        package = yazi-nvim;
        setup = # lua
          ''
            require('yazi').setup({
              open_for_directories = false,
              keymaps = {
                show_help = '<f1>',
              },
            })
          '';
      };

      render-markdown = {
        package = render-markdown-nvim;
        setup = # lua
          ''
            require('render-markdown').setup({
              file_types = { 'markdown' },
            })
          '';
      };

      nvim-metals = {
        package = nvim-metals;
        setup = # lua
          ''
            local metals_config = require('metals').bare_config()

            metals_config.settings = {
              showImplicitArguments = true,
              excludedPackages = {
                "akka.actor.typed.javadsl",
                "com.github.swagger.akka.javadsl"
              },
            }

            metals_config.init_options.statusBarProvider = "off"
            metals_config.capabilities = require('cmp_nvim_lsp').default_capabilities()

            local nvim_metals_group = vim.api.nvim_create_augroup("nvim-metals", { clear = true })
            vim.api.nvim_create_autocmd("FileType", {
              pattern = { "scala", "sbt", "java" },
              callback = function()
                require('metals').initialize_or_attach(metals_config)
              end,
              group = nvim_metals_group,
            })
          '';
      };

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
      nvim-web-devicons
    ];
  };
}
