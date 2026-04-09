{
  config,
  pkgs,
  perSystem,
  ...
}:
let
  repoDir = "${config.home.homeDirectory}/shinyflakes/nix/modules/home/programs/pi";
  mkLink = config.lib.file.mkOutOfStoreSymlink;
  pi = perSystem.llm-agents.pi;
in
{
  home = {
    packages = with pkgs; [
      pi
      ddgr
      skopeo
    ];
    file = {
      ".pi/agent/AGENTS.md".source = mkLink "${repoDir}/AGENTS.md";
      ".pi/agent/skills".source = mkLink "${repoDir}/skills";
      ".pi/agent/settings.json".source = mkLink "${repoDir}/settings.json";

      # Extensions — symlink individually so we can inject node_modules for LSP
      ".pi/agent/extensions/neovim-cursor-fix.ts".source =
        mkLink "${repoDir}/extensions/neovim-cursor-fix.ts";
      ".pi/agent/extensions/tool-guardian".source = mkLink "${repoDir}/extensions/tool-guardian";
      ".pi/agent/extensions/node_modules".source = "${pi}/lib/node_modules";
    };
  };
}
