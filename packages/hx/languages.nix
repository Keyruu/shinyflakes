{
  language-server = {
    nixd = {
      command = "nixd";
      config.nixd = {
        options = {
          nixos.expr = ''(builtins.getFlake "/home/lucas/shinyflakes").nixosConfigurations.mentat.options'';
          home_manager.expr = ''(builtins.getFlake "/home/lucas/shinyflakes").nixosConfigurations.muadib.options.home-manager.users.type.getSubOptions []'';
        };
        formatting.command = [ "nixfmt" ];
      };
    };

    nil = {
      command = "nil";
      config.nix.flake = {
        autoArchive = true;
        autoEvalInputs = true;
      };
    };
  };

  language = [
    {
      name = "html";
      language-servers = [
        "vscode-html-language-server"
        "tailwindcss-ls"
      ];
    }
    {
      name = "css";
      language-servers = [
        "vscode-css-language-server"
        "tailwindcss-ls"
      ];
    }
    {
      name = "scss";
      language-servers = [
        "vscode-css-language-server"
        "tailwindcss-ls"
      ];
    }
    {
      name = "tsx";
      language-servers = [
        "typescript-language-server"
        "tailwindcss-ls"
      ];
    }
    {
      name = "jsx";
      language-servers = [
        "typescript-language-server"
        "tailwindcss-ls"
      ];
    }
    {
      name = "svelte";
      language-servers = [
        "svelteserver"
        "tailwindcss-ls"
      ];
    }
    {
      name = "astro";
      language-servers = [
        "astro-ls"
        "tailwindcss-ls"
      ];
    }
  ];
}
