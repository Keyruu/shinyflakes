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
    ./git.nix
  ];

  sops.secrets = {
    openaiKey = { };
    anthropicKey = { };
    geminiKey = { };
    mammouthKey = { };
    opencodeKey = { };
    hcloudToken = { };
    cloudflareToken = { };
    jiraToken = { };
    datadogApiKeyMp = { };
    datadogAppKeyMp = { };
    hassKey = { };
  };
  sops.templates."shell.env".content = ''
    OPENAI_API_KEY=${config.sops.placeholder.openaiKey}
    ANTHROPIC_API_KEY=${config.sops.placeholder.anthropicKey}
    GEMINI_API_KEY=${config.sops.placeholder.geminiKey}
    MAMMOUTH_API_KEY=${config.sops.placeholder.mammouthKey}
    OPENCODE_API_KEY=${config.sops.placeholder.opencodeKey}
    CLOUDFLARE_API_TOKEN=${config.sops.placeholder.cloudflareToken}
    HCLOUD_TOKEN=${config.sops.placeholder.hcloudToken}
    TF_VAR_cloudflare_api_token=${config.sops.placeholder.cloudflareToken}
    TF_VAR_hcloud_token=${config.sops.placeholder.hcloudToken}
    JIRA_API_TOKEN=${config.sops.placeholder.jiraToken}
    DATADOG_APP_KEY_MP=${config.sops.placeholder.datadogAppKeyMp}
    DATADOG_APP_KEY_MP=${config.sops.placeholder.datadogAppKeyMp}
    HASS_KEY=${config.sops.placeholder.hassKey}
  '';

  home.sessionVariables = {
    # clean up ~
    LESSHISTFILE = cache + "/less/history";
    LESSKEY = c + "/less/lesskey";
    WINEPREFIX = d + "/wine";

    # set default applications
    EDITOR = "nvim";
    BROWSER = "zen-beta";
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
    };
  };
}
