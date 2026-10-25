{ pkgs }:
let
  source = pkgs.lib.fileset.toSource {
    root = ../modules/aspects/agents/pi;
    fileset = pkgs.lib.fileset.unions [
      ../modules/aspects/agents/pi/package.json
      ../modules/aspects/agents/pi/cli/pi-task.ts
      ../modules/aspects/agents/pi/cli/review.ts
      ../modules/aspects/agents/pi/cli/runtime.ts
      ../modules/aspects/agents/pi/lib/task-state.ts
    ];
  };
in
pkgs.writeShellApplication {
  name = "pi-task";
  runtimeInputs = with pkgs; [
    nodejs
    bash
    git
    zellij
    fzf
    zoxide
    coreutils
    util-linux
  ];
  # Editor, agent, and desktop terminal still come from the configured user session.
  text = ''
    exec node --experimental-strip-types "${source}/cli/pi-task.ts" "$@"
  '';
}
