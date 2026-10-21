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
    util-linux # setsid
  ];
  # mmsg/vicinae/footclient come from the session PATH to match the running desktop.
  text = builtins.readFile ./zs.sh;
}
