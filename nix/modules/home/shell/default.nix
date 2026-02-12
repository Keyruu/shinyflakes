{
  config,
  ...
}:
let
  d = config.xdg.dataHome;
  c = config.xdg.configHome;
  cache = config.xdg.cacheHome;
in
{
  imports = [
    ./atuin.nix
    ./fish.nix
    ./k9s.nix
    ./lazygit.nix
    ./television.nix
    ./tmux.nix
    ./yazi.nix
    ./zellij.nix
    ./zsh.nix
  ];

  sops.secrets = {
    openaiKey = { };
    anthropicKey = { };
    geminiKey = { };
    mammouthKey = { };
    hcloudToken = { };
    cloudflareToken = { };
  };
  sops.templates."shell.env".content = ''
    OPENAI_API_KEY=${config.sops.placeholder.openaiKey}
    ANTHROPIC_API_KEY=${config.sops.placeholder.anthropicKey}
    GEMINI_API_KEY=${config.sops.placeholder.geminiKey}
    MAMMOUTH_API_KEY=${config.sops.placeholder.mammouthKey}
    CLOUDFLARE_API_TOKEN=${config.sops.placeholder.cloudflareToken}
    HCLOUD_TOKEN=${config.sops.placeholder.hcloudToken}
    TF_VAR_cloudflare_api_token=${config.sops.placeholder.cloudflareToken}
    TF_VAR_hcloud_token=${config.sops.placeholder.hcloudToken}
  '';

  home.sessionVariables = {
    # clean up ~
    LESSHISTFILE = cache + "/less/history";
    LESSKEY = c + "/less/lesskey";
    WINEPREFIX = d + "/wine";

    # set default applications
    EDITOR = "nvim";
    BROWSER = "firefox";
    TERMINAL = "alacritty";

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
    deploy-mentat = "nixos-rebuild --flake ~/shinyflakes#mentat switch --target-host root@192.168.100.7 --build-host root@192.168.100.7 --no-reexec";
    deploy-prime = "nixos-rebuild --flake ~/shinyflakes#prime switch --target-host root@prime --build-host root@prime --no-reexec";
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
  };
}
