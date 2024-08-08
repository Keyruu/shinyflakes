{pkgs, ...}:
# nix tooling
{
  programs.zsh = {
    enable = true;

    initExtra =
      /*
      bash
      */
      ''
        eval "$(/opt/homebrew/bin/brew shellenv)"

        bindkey -M viins "^[[A" history-substring-search-up
        bindkey -M viins "^[[B" history-substring-search-down
      '';

    dotDir = ".config/zsh";
    autosuggestion.enable = true;
    enableCompletion = true;

    syntaxHighlighting.enable = false;
    historySubstringSearch = {
      enable = true;
      searchUpKey = ["j" "^[[A"];
      searchDownKey = ["k" "^[[B"];
    };

    shellAliases = {
      mv = "mv -iv";
      rm = "rm -I";
      cp = "cp -iv";
      ln = "ln -iv";
      please = "sudo $(fc -ln -1)";
      lf = "lfub";
      gs = "git status";
      gd = "git diff";
      ga = "git add";
      gc = "git clone";
      ssh = "TERM=xterm-256color ssh";
      "cd ..." = "cd ../..";
      "cd ...." = "cd ../../..";
      copy = "xclip -selection clipboard";
      dev = "nix develop --impure -c $SHELL";
      git-branch-cleanup = "git branch -vv | grep gone | awk '{print $1}' | xargs git branch -D";
      ztab = "zellij action new-tab";
    };

    history = {
      size = 1000000;
      save = 1000000;
      ignorePatterns = ["cd ..*" "ls"];
      extended = true;
    };

    envExtra = ''
      export PATH="''${KREW_ROOT:-$HOME/.krew}/bin:$PATH"
      export PATH="$HOME/.cargo/bin:$PATH"
      export PATH="$HOME/Library/Application Support/JetBrains/Toolbox/scripts/:$PATH"

      export KUBECONFIG=$HOME/.kube/config
      export KUBECONFIG=$KUBECONFIG:$HOME/.kube/galaxy.yaml
      export KUBECONFIG=$KUBECONFIG:$HOME/.kube/traversetown.yaml
      export KUBECONFIG=$KUBECONFIG:$HOME/.kube/pdarobe.yaml
    '';

    antidote = {
      enable = true;
      plugins = [
        "ohmyzsh/ohmyzsh path:lib"
        "ohmyzsh/ohmyzsh path:plugins/extract"
        "ohmyzsh/ohmyzsh path:plugins/magic-enter"
        "MichaelAquilina/zsh-you-should-use"
        "zdharma-continuum/fast-syntax-highlighting kind:defer"
        "wfxr/forgit"
        "jeffreytse/zsh-vi-mode"
        "lukechilds/zsh-nvm"
        "ahmetb/kubectx path:completion kind:fpath"
      ];
    };
  };

  programs.starship = {
    enable = true;
    enableZshIntegration = true;
  };
  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
  };
  programs.zoxide = {
    enable = true;
    enableZshIntegration = true;
  };
  programs.lsd = {
    enable = true;
    enableAliases = true;
  };
  programs.bat.enable = true;
  programs.thefuck = {
    enable = true;
    enableZshIntegration = true;
  };

  programs.direnv = {
    enable = true;
    enableZshIntegration = true;
  };
}
