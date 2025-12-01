{ lib, pkgs, ... }:
{
  xdg.desktopEntries.colorpicker = {
    name = "Colorpicker";
    exec = "${lib.getExe pkgs.wl-color-picker} clipboard";
    terminal = false;
    type = "Application";
    categories = [ "Utility" ];
    icon = "colors";
  };
}
