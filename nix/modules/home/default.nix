{ flake, ... }:
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
    flake.modules.private.calendar

    ./mail.nix
    flake.modules.private.mail

    ./gaming.nix
    ./mpv.nix
    ./nix-index-database.nix
    ./repos.nix
    ./ssh.nix
    ./tailscale.nix
    ./gaming.nix
    ./element.nix
  ];
}
