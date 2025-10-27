{ pkgs, lib, ... }:
let
  idleService = "swayidle";

  caffeine-status = pkgs.writeShellScriptBin "caffeine-status" ''
    [[ $(pidof "${idleService}") ]] && echo "" || echo "󰅶"
  '';

  caffeine = pkgs.writeShellScriptBin "caffeine" ''
    if [[ $(pidof "${idleService}") ]]; then
      systemctl --user stop ${idleService}.service
      title="Caffeine activated"
      description="Caffeine is now active! Your screen will not turn off automatically."
    else
      systemctl --user start ${idleService}.service
      title="Caffeine deactivated"
      description="Caffeine is now deactivated! Your screen will turn off automatically."
    fi

    notif "caffeine" "$title" "$description"
  '';

in
{
  home.packages = [
    caffeine-status
    caffeine
  ];

  xdg.desktopEntries.caffeine = {
    name = "Caffeine";
    exec = "${lib.getExe caffeine}";
    terminal = false;
    type = "Application";
    categories = [ "Utility" ];
    icon = "caffeine";
  };
}
