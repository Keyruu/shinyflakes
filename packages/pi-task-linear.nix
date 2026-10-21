{ pkgs }:
pkgs.writeShellApplication {
  name = "pi-task-linear";
  runtimeInputs = [
    pkgs.curl
    pkgs.jq
    pkgs.fzf
    pkgs.coreutils
    (pkgs.callPackage ./pi-task.nix { })
  ];
  text = builtins.readFile ./pi-task-linear.sh;
}
