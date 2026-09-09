{ ... }:
{
  den.aspects.tools.colorpicker = {
    homeManager =
      { lib, pkgs, ... }:
      {
        xdg.desktopEntries.colorpicker = {
          name = "Colorpicker";
          exec = "${lib.getExe pkgs.wl-color-picker} clipboard";
          categories = [ "Utility" ];
          icon = "colors";
        };
      };
  };
}
