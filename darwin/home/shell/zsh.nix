{pkgs, ...}:
# nix tooling
{
  programs.zsh = {
    enable = true;

    initExtra = ''
      eval "$(/opt/homebrew/bin/brew shellenv)"
    '';

    dotDir = ".config/zsh";
    enableAutosuggestions = true;
    enableCompletion = true;

    syntaxHighlighting.enable = false;
    historySubstringSearch = {
      enable = true;
      searchUpKey = ["^[j" "^[[A" "$terminfo[kcuu1]" "\eOA"];
      searchDownKey = ["^[k" "^[[B" "$terminfo[kcud1]" "\eOB"];
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
      export KUBECONFIG=$KUBECONFIG:$HOME/.kube/galaxy.kubeconfig
      export KUBECONFIG=$KUBECONFIG:$HOME/.kube/traversetown.kubeconfig
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

  programs.starship.enable = true;
  programs.fzf.enable = true;
  programs.zoxide.enable = true;
  programs.lsd = {
    enable = true;
    enableAliases = true;
  };
  programs.bat.enable = true;
}
