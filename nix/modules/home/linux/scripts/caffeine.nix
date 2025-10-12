# - ## Caffeine
#-
#- Caffeine is a simple script that toggles hypridle (disable suspend & screenlock).
#-
#- - `caffeine-status` - Check if hypridle is running. (0/1)
#- - `caffeine-status-icon` - Check if hypridle is running. (icon)
#- - `caffeine` - Toggle hypridle.

{ pkgs, lib, ... }:
let
  idleService = "swayidle";

  caffeine-status = pkgs.writeShellScriptBin "caffeine-status" ''
    [[ $(pidof "${idleService}") ]] && echo "0" || echo "1"
  '';

  caffeine-status-icon = pkgs.writeShellScriptBin "caffeine-status-icon" ''
    [[ $(pidof "${idleService}") ]] && echo "󰾪" || echo "󰅶"
  '';

  caffeine = pkgs.writeShellScriptBin "caffeine" ''
    if [[ $(pidof "${idleService}") ]]; then
      systemctl --user stop ${idleService}.service
      title="󰅶  Caffeine Activated"
      description="Caffeine is now active! Your screen will not turn off automatically."
    else
      systemctl --user start ${idleService}.service
      title="󰾪  Caffeine Deactivated"
      description="Caffeine is now deactivated! Your screen will turn off automatically."
    fi

    notif "caffeine" "$title" "$description"
  '';

in
{
  home.packages = [
    caffeine-status
    caffeine
    caffeine-status-icon
  ];

  xdg.desktopEntries.caffeine = {
    name = "☕ Caffeine";
    exec = "${lib.getExe caffeine}";
    terminal = false;
    type = "Application";
    categories = [ "Utility" ];
    icon = "system-run";
  };
}
