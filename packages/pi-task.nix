{ pkgs }:
pkgs.writeShellApplication {
  name = "pi-task";
  runtimeInputs = with pkgs; [
    git
    zellij
    jq
    fzf
    zoxide
    coreutils
    gawk
    gnugrep
    util-linux
  ];
  # Use the configured editor, agent, and login shell from the user session.
  extraShellCheckFlags = [ "--external-sources" ];
  text =
    builtins.replaceStrings [ "source=packages/pi-task-state.sh" ] [ "source=${./pi-task-state.sh}" ]
      ''
        PI_TASK_STATE_LIBRARY=${./pi-task-state.sh}
        ${builtins.readFile ./pi-task.sh}
      '';
}
