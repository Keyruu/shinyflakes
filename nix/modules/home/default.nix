{ ... }:
{
  imports = [
    ./core.nix
    ./wm
    ./shell
    ./programs
    ./scripts.nix
    ./clipse.nix
    # ./dunst.nix
    # ./swaync.nix
    # ./tofi.nix
    # ./workstyle.nix

    ./themes/theme.nix

    ./calendar.nix
    ./gaming.nix
    ./mpv.nix
    ./nix-index-database.nix
    ./repos.nix
    ./ssh.nix
    ./tailscale.nix
  ];
}
