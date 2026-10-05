{ pkgs }:
pkgs.writeShellApplication {
  name = "claude-review";
  runtimeInputs = with pkgs; [
    coreutils
    git
    jq
  ];
  # nvim and zellij come from the session PATH so the client matches the
  # running editor / multiplexer. The lua is dofile'd into the live nvim on
  # every `open`, so the editor needs no plugin install or restart.
  text = ''
    PLUGIN_LUA=${./review.lua}
  ''
  + builtins.readFile ./claude-review.sh;
}
