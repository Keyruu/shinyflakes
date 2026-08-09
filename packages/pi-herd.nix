{ pkgs }:
pkgs.writeShellApplication {
  name = "pi-herd";
  runtimeInputs = with pkgs; [
    fzf
    jq
    coreutils
    gnugrep
    gnused
    gawk
    niri
    zellij
    util-linux # setsid
  ];
  # vicinae/footclient intentionally not in the closure — desktop apps,
  # resolved from the user session PATH in --dmenu mode
  text = builtins.readFile ./pi-herd.sh;
}
