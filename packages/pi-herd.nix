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
  # mmsg/vicinae/footclient come from the session PATH to match the running desktop.
  extraShellCheckFlags = [ "--external-sources" ];
  text =
    builtins.replaceStrings [ "source=packages/pi-task-state.sh" ] [ "source=${./pi-task-state.sh}" ]
      ''
        PI_TASK_STATE_LIBRARY=${./pi-task-state.sh}
        ${builtins.readFile ./pi-herd.sh}
      '';
}
