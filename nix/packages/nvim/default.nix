{
  inputs,
  pkgs,
  perSystem,
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
        which-key.data = which-key-nvim;
        highlight-undo.data = highlight-undo-nvim;
        mini.data = mini-nvim;
        conform.data = conform-nvim;
        snacks.data = snacks-nvim;
        flash.data = flash-nvim;
        todo.data = todo-comments-nvim;
        yazi.data = yazi-nvim;
        grugfar.data = grug-far-nvim;
        outline.data = outline-nvim;
        numbertoggle.data = nvim-numbertoggle;
        smart-splits.data = smart-splits-nvim;
        direnv.data = direnv-vim;
        render-markdown.data = render-markdown-nvim;
        quicker.data = quicker-nvim;
        # perSystem custom plugins
        jira.data = perSystem.self.jira-nvim;
        piguard.data = perSystem.self.pi-guardian-nvim;
      };
    }
  )
]
