{ ... }:
{
  imports = [
    ./core.nix
    ./wm
    ./shell
    ./programs
    ./scripts
    ./clipse.nix
    # ./dunst.nix
    # ./swaync.nix
    # ./tofi.nix

    ./themes/theme.nix

    ./calendar.nix
    ./mail.nix
    ./gaming.nix
    ./mpv.nix
    ./nix-index-database.nix
    ./repos.nix
    ./ssh.nix
    ./tailscale.nix
    ./gaming.nix
  ];
}
