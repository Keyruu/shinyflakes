{ pkgs }:
pkgs.writeShellApplication {
  name = "orca-diff";
  runtimeInputs = with pkgs; [
    git
    coreutils
    util-linux # setsid
  ];
  # kitty and nvim come from the session PATH to match the running desktop.
  text = builtins.readFile ./orca-diff.sh;
}
