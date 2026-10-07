{ pkgs }:
pkgs.writeShellApplication {
  name = "mesh-tunnel";
  runtimeInputs = with pkgs; [
    systemd
    coreutils
    gnugrep
    gnused
    fzf
  ];
  # vicinae intentionally not in the closure — desktop app, resolved from
  # the user session PATH in --dmenu mode
  text = builtins.readFile ./mesh-tunnel.sh;
}
