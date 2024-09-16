{...}: {
  programs.fish = {
    enable = true;

    shellInit =
      /*
      fish
      */
      ''
        eval "$(/opt/homebrew/bin/brew shellenv)"
        fish_vi_key_bindings

        fish_add_path $HOME/.krew
        fish_add_path $HOME/.cargo/bin
        fish_add_path $HOME/Library/Application\ Support/JetBrains/Toolbox/scripts/

        set -x KUBECONFIG $HOME/.kube/config
        set -x KUBECONFIG $KUBECONFIG:$HOME/.kube/jq-production-sysops.yaml
        set -x KUBECONFIG $KUBECONFIG:$HOME/.kube/kl-production-sysops.yaml
        set -x KUBECONFIG $KUBECONFIG:$HOME/.kube/kl-staging-sysops.yaml
        set -x KUBECONFIG $KUBECONFIG:$HOME/.kube/mp-staging-sysops.yaml
        set -x KUBECONFIG $KUBECONFIG:$HOME/.kube/mp-production-sysops.yaml
        set -x KUBECONFIG $KUBECONFIG:$HOME/.kube/mp-shared-services-sysops.yaml
        set -x KUBECONFIG $KUBECONFIG:$HOME/.kube/ph-production-sysops.yaml
      '';

    shellInitLast =
      /*
      fish
      */
      ''
        enable_transience
      '';

    shellAbbrs = {
      mv = "mv -iv";
      rm = "rm -I";
      cp = "cp -iv";
      ln = "ln -iv";
      lf = "lfub";
      gs = "git status";
      gd = "git diff";
      ga = "git add";
      gc = "git clone";
      ssh = "TERM=xterm-256color ssh";
      ztab = "zellij action new-tab";
      vi = "nvim";
    };
  };
}
