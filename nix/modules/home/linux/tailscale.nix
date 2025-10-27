{ pkgs, ... }:
{
  home.packages = with pkgs; [
    tailscale
    tailscale-systray
  ];
}
