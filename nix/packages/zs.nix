{ pkgs }:
pkgs.writeShellApplication {
  name = "zs";
  runtimeInputs = with pkgs; [
    zellij
    zoxide
    fzf
    jq
    gawk
    gnused
    gnugrep
    coreutils
    niri
    nirius
    util-linux # setsid
  ];
  # vicinae/footclient intentionally not in the closure — desktop apps,
  # resolved from the user session PATH in --dmenu mode
  text = builtins.readFile ./zs.sh;
}
