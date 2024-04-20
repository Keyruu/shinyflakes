{
  pkgs,
  ...
}:
# nix tooling
{
  programs.zsh = {
    enable = true;

    dotDir = ".config/zsh";
    autosuggestion.enable = true;
    enableCompletion = true;

    syntaxHighlighting.enable = false;
    historySubstringSearch = {
      enable = true;
      searchUpKey = ["^[j" "^[[A" "$terminfo[kcuu1]"];
      searchDownKey = ["^[k" "^[[B" "$terminfo[kcud1]"];
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

    antidote = {
      enable = true;
      plugins = [
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
