{ ... }:
{
  programs.nh = {
    enable = true;
    clean.enable = true;
    clean.extraArgs = "--keep-since 10d --keep 5";
    flake = "$HOME/shinyflakes";
  };
}
