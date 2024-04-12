{
  pkgs,
  ...
}:
# nix tooling
{
  programs.zsh = {
    enable = true;

    dotDir = ".config/zsh";
    enableAutosuggestions = true;
    enableCompletion = true;

    syntaxHighlighting.enable = true;
    historySubstringSearch = {
      enable = true;
      searchUpKey = ["^[j" "^[[A"];
      searchDownKey = ["^[k" "^[[B"];
    };

    shellAliases = {
      ls = "ls --color=auto";
      mv = "mv -iv";
      rm = "rm -I";
      cp = "cp -iv";
      ln = "ln -iv";
      please = "sudo $(fc -ln -1)";
      lf = "lfub";
      gs = "git status";
      gd = "git diff";
      ga = "git add";
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
  };
 
  programs.starship.enable = true;
  programs.fzf.enable = true;
}
