{ pkgs }:
pkgs.writeShellApplication {
  name = "pi-herd";
  runtimeInputs = with pkgs; [
    (import ./pi-task.nix { inherit pkgs; })
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
  # mmsg/vicinae/footclient come from the session PATH to match the running desktop.
  text = builtins.readFile ./pi-herd.sh;
}
