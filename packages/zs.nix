{ pkgs }:
let
  source = pkgs.lib.fileset.toSource {
    root = ./zs;
    fileset = pkgs.lib.fileset.unions [
      ./zs/main.ts
      ./zs/commands.ts
      ./zs/github.ts
      ./zs/presentation.ts
      ./zs/text.ts
      ./zs/package.json
    ];
  };
in
pkgs.writeShellApplication {
  name = "zs";
  runtimeInputs = with pkgs; [
    zellij
    zoxide
    fzf
    bash
    gawk
    git
    gh
    nodejs
    glibc.bin # getconf supplies the kernel clock tick rate for PID reuse checks.
  ];
  # vicinae/kitty come from the session PATH to match the running desktop.
  text = ''
    export ZS_HELPER=${source}/main.ts
    ${builtins.readFile ./zs.sh}
  '';
}
