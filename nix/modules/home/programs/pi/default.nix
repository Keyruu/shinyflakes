{
  config,
  pkgs,
  inputs,
  ...
}:
let
  repoDir = "${config.home.homeDirectory}/shinyflakes/nix/modules/home/programs/pi";
  mkLink = config.lib.file.mkOutOfStoreSymlink;
  small = import inputs.nixpkgs-small {
    inherit (pkgs.stdenv.hostPlatform) system;
    config.allowUnfree = true;
  };
in
{
  home = {
    packages = with pkgs; [
      small.pi-coding-agent
      ddgr
      skopeo
    ];
    file = {
      ".pi/agent/extensions".source = mkLink "${repoDir}/extensions";
      ".pi/agent/AGENTS.md".source = mkLink "${repoDir}/AGENTS.md";
      ".pi/agent/skills".source = mkLink "${repoDir}/skills";
    };
  };
}
