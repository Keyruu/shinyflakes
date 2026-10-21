{
  inputs,
  pkgs,
  jira-nvim,
  pi-guardian-nvim,
  ...
}:
inputs.nix-wrapper-modules.lib.evalPackage [
  { inherit pkgs; }
  (
    {
      wlib,
      ...
    }:
    {
      imports = [ wlib.wrapperModules.neovim ];

      binName = "nvim";

      # Strip share/nvim so this can replace nvf's nvim in home.packages later
      # without a path collision.
      settings.dont_link = true;
      settings.config_directory = ./.;

      runtimePkgs = with pkgs; [
        # LSPs
        nixd
        nil
        gopls
        rust-analyzer
        typescript-language-server
        typescript
        bash-language-server
        tailwindcss-language-server
        vscode-json-languageserver
        helm-ls
        terraform-ls
        yaml-language-server
        astro-language-server
        svelte-language-server
        svelte-check
        lua-language-server
        marksman
        # formatters (conform / format-on-save)
        alejandra
        nixfmt
        stylua
        prettier
        markdownlint-cli2
      ];

      specs = with pkgs.vimPlugins; {
        kanagawa.data = kanagawa-nvim;
        blink.data = blink-cmp;
        lazydev.data = lazydev-nvim;
        lspconfig.data = nvim-lspconfig;
        trouble.data = trouble-nvim;
        # grammars.data = map pkgs.vimPlugins.nvim-treesitter.grammarToPlugin (
        #   builtins.attrValues pkgs.vimPlugins.nvim-treesitter.builtGrammars
        # );
        nvim-treesitter.data = nvim-treesitter.withAllGrammars;
        treesitter-context.data = nvim-treesitter-context;
        gitsigns.data = gitsigns-nvim;
        comment.data = comment-nvim;
        autopairs.data = nvim-autopairs;
        lualine.data = lualine-nvim;
        devicons.data = nvim-web-devicons;
        colorizer.data = nvim-colorizer-lua;
        noice.data = noice-nvim;
        tiny-cmdline.data = tiny-cmdline-nvim;
        which-key.data = which-key-nvim;
        highlight-undo.data = highlight-undo-nvim;
        mini.data = mini-nvim;
        conform.data = conform-nvim;
        snacks.data = snacks-nvim;
        fzf-lua.data = fzf-lua;
        flash.data = flash-nvim;
        todo.data = todo-comments-nvim;
        yazi.data = yazi-nvim;
        grugfar.data = grug-far-nvim;
        outline.data = outline-nvim;
        numbertoggle.data = nvim-numbertoggle;
        smart-splits.data = smart-splits-nvim;
        smart-splits-backend-zellij.data = pkgs.vimUtils.buildVimPlugin {
          pname = "smart-splits-backend-zellij-lua";
          version = "1.0.0";
          src = pkgs.fetchFromGitHub {
            owner = "smart-splits-nvim";
            repo = "backend-zellij-lua";
            rev = "4e3e588795efb95548dd2ebeaf385a7823821ceb";
            hash = "sha256-QAKX3jHYd2xHjhs8uf44OB04Q+Gl+wXVZOqS09IcRSk=";
          };
        };
        smart-splits-backend-tmux.data = pkgs.vimUtils.buildVimPlugin {
          pname = "smart-splits-backend-tmux";
          version = "unstable-2026-10-02";
          src = pkgs.fetchFromGitHub {
            owner = "smart-splits-nvim";
            repo = "backend-tmux";
            rev = "9e9e6aa9b3eb7a8d3896a993611622ac97abff52";
            hash = "sha256-RcJdM6wFHZOEOK+cXVIT10anktqGgIilPmojFpdY+4g=";
          };
        };
        direnv.data = direnv-vim;
        spider.data = nvim-spider;
        various-textobjs.data = nvim-various-textobjs;
        render-markdown.data = render-markdown-nvim;
        quicker.data = quicker-nvim;
        lint.data = nvim-lint;
        orgmode.data = orgmode;
        diffview.data = diffview-plus-nvim.overrideAttrs {
          name = "vimplugin-diffview-plus.nvim-0.39";
          version = "0.39";
          src = pkgs.fetchFromGitHub {
            owner = "dlyongemallo";
            repo = "diffview-plus.nvim";
            rev = "2a2d89a07f5d5d3cef7f542b99c3e28050ca205c";
            hash = "sha256-0Zu2HPU9rzsyIOVLPWB9ABmfu5UffYkJtkIQUtBLVOs=";
          };
        };
        # perSystem custom plugins
        jira.data = jira-nvim;
        piguard.data = pi-guardian-nvim;
      };
    }
  )
]
