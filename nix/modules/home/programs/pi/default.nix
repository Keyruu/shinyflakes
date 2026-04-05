{ config, pkgs, ... }:
let
  repoDir = "${config.home.homeDirectory}/shinyflakes/nix/modules/home/programs/pi";
  mkLink = config.lib.file.mkOutOfStoreSymlink;
in
{
  home.packages = with pkgs; [
    pi-coding-agent
    ddgr
  ];

  home.file.".pi/agent/extensions".source = mkLink "${repoDir}/extensions";
  home.file.".pi/agent/AGENTS.md".source = mkLink "${repoDir}/AGENTS.md";
  home.file.".pi/agent/skills".source = mkLink "${repoDir}/skills";
}
