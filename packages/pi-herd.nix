{ pkgs }:
pkgs.writeShellApplication {
  name = "pi-herd";
  runtimeInputs = with pkgs; [
    fzf
    git
    jq
    coreutils
    gnugrep
    gnused
    gawk
    zellij
    util-linux # setsid
  ];
  # mmsg/vicinae/kitty come from the session PATH to match the running desktop.
  text = builtins.readFile ./pi-herd.sh;
}
