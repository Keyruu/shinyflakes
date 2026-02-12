{ flake, ... }:
{
  imports = with flake.modules.home; [
    core
    wm
    shell
    programs
    scripts
    clipse

    ./themes/theme.nix

    calendar
    flake.modules.private.calendar

    mail
    flake.modules.private.mail

    gaming
    mpv
    nix-index-database
    repos
    ssh
    gaming
    element
  ];
}
