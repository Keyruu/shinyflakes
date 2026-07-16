{ flake, ... }:
{
  imports = [
    ./terminals
    ./editors
    ./browsers

    ./1password.nix
    ./nh.nix
    ./noctalia.nix
    ./satty.nix
    ./spotify.nix
    ./vicinae.nix
    ./zathura.nix

    flake.modules.agents.pi
    flake.modules.agents.opencode
    flake.modules.agents.claude-code
  ];
}
