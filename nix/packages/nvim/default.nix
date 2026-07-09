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

      specs = {
        kanagawa.data = pkgs.vimPlugins.kanagawa-nvim;
        blink.data = pkgs.vimPlugins.blink-cmp;
        lazydev.data = pkgs.vimPlugins.lazydev-nvim;
        lspconfig.data = pkgs.vimPlugins.nvim-lspconfig;
        trouble.data = pkgs.vimPlugins.trouble-nvim;
        # grammars.data = map pkgs.vimPlugins.nvim-treesitter.grammarToPlugin (
        #   builtins.attrValues pkgs.vimPlugins.nvim-treesitter.builtGrammars
        # );
        nvim-treesitter.data = pkgs.vimPlugins.nvim-treesitter.withAllGrammars;
        treesitter-context.data = pkgs.vimPlugins.nvim-treesitter-context;
        gitsigns.data = pkgs.vimPlugins.gitsigns-nvim;
        comment.data = pkgs.vimPlugins.comment-nvim;
        autopairs.data = pkgs.vimPlugins.nvim-autopairs;
        lualine.data = pkgs.vimPlugins.lualine-nvim;
        devicons.data = pkgs.vimPlugins.nvim-web-devicons;
        colorizer.data = pkgs.vimPlugins.nvim-colorizer-lua;
        noice.data = pkgs.vimPlugins.noice-nvim;
        which-key.data = pkgs.vimPlugins.which-key-nvim;
        highlight-undo.data = pkgs.vimPlugins.highlight-undo-nvim;
        mini.data = pkgs.vimPlugins.mini-nvim;
        conform.data = pkgs.vimPlugins.conform-nvim;
        snacks.data = pkgs.vimPlugins.snacks-nvim;
        flash.data = pkgs.vimPlugins.flash-nvim;
        todo.data = pkgs.vimPlugins.todo-comments-nvim;
        yazi.data = pkgs.vimPlugins.yazi-nvim;
        grugfar.data = pkgs.vimPlugins.grug-far-nvim;
        outline.data = pkgs.vimPlugins.outline-nvim;
        numbertoggle.data = pkgs.vimPlugins.nvim-numbertoggle;
        smart-splits.data = pkgs.vimPlugins.smart-splits-nvim;
        direnv.data = pkgs.vimPlugins.direnv-vim;
        render-markdown.data = pkgs.vimPlugins.render-markdown-nvim;
        # perSystem custom plugins
        jira.data = perSystem.self.jira-nvim;
        piguard.data = perSystem.self.pi-guardian-nvim;
      };
    }
  )
]
