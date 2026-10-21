{ ... }:
{
  den.aspects.tools.sone = {
    homeManager =
      {
        config,
        inputs',
        lib,
        pkgs,
        ...
      }:
      {
        home.packages = [ pkgs.sone ];

        xdg.desktopEntries.SONE = lib.mkIf config.wayland.windowManager.mango.enable {
          name = "SONE";
          exec = "${pkgs.writeShellScript "sone-scratchpad" ''
            if [ "$#" -gt 0 ]; then
              exec ${pkgs.sone}/bin/sone "$@"
            fi
            exec ${inputs'.mango.packages.mango}/bin/mmsg dispatch 'toggle_named_scratchpad,^sone$,none,${pkgs.sone}/bin/sone'
          ''} %u";
          icon = "sone";
          settings.StartupWMClass = "sone";
          terminal = false;
          categories = [
            "AudioVideo"
            "Audio"
            "Music"
          ];
          mimeType = [ "x-scheme-handler/tidal" ];
        };
      };
  };
}
