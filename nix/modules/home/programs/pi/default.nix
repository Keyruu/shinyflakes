{
  config,
  pkgs,
  perSystem,
  ...
}:
let
  repoDir = "${config.home.homeDirectory}/shinyflakes/nix/modules/home/programs/pi";
  mkLink = config.lib.file.mkOutOfStoreSymlink;
in
{
  home = {
    packages = with pkgs; [
      perSystem.llm-agents.pi
      ddgr
      skopeo
    ];
    file = {
      ".pi/agent/extensions".source = mkLink "${repoDir}/extensions";
      ".pi/agent/AGENTS.md".source = mkLink "${repoDir}/AGENTS.md";
      ".pi/agent/skills".source = mkLink "${repoDir}/skills";
      ".pi/agent/settings.json".source = mkLink "${repoDir}/settings.json";
    };
  };
}
