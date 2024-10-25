{
  config,
  pkgs,
  ...
}: let
  d = config.xdg.dataHome;
  c = config.xdg.configHome;
  cache = config.xdg.cacheHome;
in {
  imports = [
    ./zsh.nix
    ./yazi.nix
    ./k9s.nix
    ./alacritty.nix
    ./lazygit.nix
    ./wezterm.nix
    ./zellij.nix
    ./fish.nix
    ./atuin.nix
  ];

  # add environment variables
  home.sessionVariables = {
    # clean up ~
    LESSHISTFILE = cache + "/less/history";
    LESSKEY = c + "/less/lesskey";
    WINEPREFIX = d + "/wine";

    # set default applications
    EDITOR = "nvim";
    BROWSER = "firefox";
    TERMINAL = "kitty";

    # enable scrolling in git diff
    DELTA_PAGER = "less -R";

    MANPAGER = "sh -c 'col -bx | bat -l man -p'";
  };

  home.shellAliases = {
    k = "kubectl";
  };

  programs.starship = {
    enable = true;
    enableTransience = true;
    settings = {
      right_format = "$time";
      kubernetes = {
        disabled = false;
      };
      time = {
        disabled = false;
      };
    };
  };
  programs.fzf.enable = true;
  programs.zoxide.enable = true;
  programs.lsd = {
    enable = true;
    enableAliases = true;
  };
  programs.bat.enable = true;
  programs.thefuck.enable = true;
  programs.direnv.enable = true;
}
