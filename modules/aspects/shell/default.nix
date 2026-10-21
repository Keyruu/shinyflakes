{ den, ... }: {
  den.aspects.shell.default = {
    includes = with den.aspects.shell; [
      fish
      ssh
      tmux
      zellij
      zsh
    ];

    homeManager = { config, ... }: {
      sops.secrets = {
        scalewayKey = { };
        hcloudToken = { };
        cloudflareToken = { };
        hassKey = { };
        zaiKey = { };
        minimaxKey = { };
        linearApiKey = { };
      };

      sops.templates."shell.env".content = ''
        SCALEWAY_API_KEY=${config.sops.placeholder.scalewayKey}
        CLOUDFLARE_API_TOKEN=${config.sops.placeholder.cloudflareToken}
        HCLOUD_TOKEN=${config.sops.placeholder.hcloudToken}
        TF_VAR_cloudflare_api_token=${config.sops.placeholder.cloudflareToken}
        TF_VAR_hcloud_token=${config.sops.placeholder.hcloudToken}
        HASS_KEY=${config.sops.placeholder.hassKey}
        ZAI_API_KEY=${config.sops.placeholder.zaiKey}
        MINIMAX_API_KEY=${config.sops.placeholder.minimaxKey}
        LINEAR_API_KEY=${config.sops.placeholder.minimaxKey}
      '';

      home.sessionVariables = {
        # clean up ~
        LESSHISTFILE = config.xdg.cacheHome + "/less/history";
        LESSKEY = config.xdg.configHome + "/less/lesskey";
        WINEPREFIX = config.xdg.dataHome + "/wine";

        # set default applications
        EDITOR = "nvim";
        BROWSER = "browser-picker";
        TERMINAL = "footclient";

        # enable scrolling in git diff
        DELTA_PAGER = "less -R";

        # MANPAGER = "sh -c 'col -bx | bat -l man -p'";
        PNPM_HOME = "$HOME/.pnpm-bin";
      };

      home.shellAliases = {
        k = "kubectl";
        mv = "mv -iv";
        rm = "rm -I";
        cp = "cp -iv";
        ln = "ln -iv";
        lf = "lfub";
        gs = "git status";
        gd = "git diff";
        ga = "git add";
        gc = "git clone";
        ztab = "zellij action new-tab";
        vi = "nvim";
        ".." = "cd ..";
        "..." = "cd ../..";
        deploy-mentat = "nixos-rebuild --flake ~/shinyflakes?submodules=1#mentat switch --target-host root@192.168.100.7 --build-host root@192.168.100.7 --no-reexec";
        deploy-prime = "nixos-rebuild --flake ~/shinyflakes?submodules=1#prime switch --target-host root@prime --build-host root@prime --no-reexec";
        select-k9s = ''KUBECONFIG="$(find ~/.kube -maxdepth 1 -type f -name "*.yml" -o -name "*.yaml" -o -name "config" | fzf --prompt="Select kubeconfig: ")" k9s'';
      };

      programs = {
        starship = {
          enable = true;
          enableTransience = false;
          enableFishIntegration = false;

          settings = {
            right_format = "$time";
            kubernetes = {
              disabled = true;
            };
            time = {
              disabled = false;
            };
          };
        };

        fzf.enable = true;
        zoxide.enable = true;
        lsd = {
          enable = true;
          enableFishIntegration = true;
        };
        bat.enable = true;
        direnv.enable = true;
        mise = {
          enable = true;
          enableFishIntegration = true;
          globalConfig.settings.disable_tools = [ "aqua:aws/aws-cli" ];
        };
      };
    };
  };
}
