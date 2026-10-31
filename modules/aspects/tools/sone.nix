{ ... }:
{
  den.aspects.tools.sone = {
    homeManager =
      {
        config,
        lib,
        pkgs,
        ...
      }:
      {
        home.packages = [ pkgs.sone ];

        xdg.desktopEntries.SONE = lib.mkIf config.programs.umbriel.enable {
          name = "SONE";
          exec = "${pkgs.writeShellScript "sone-scratchpad" ''
            if [ "$#" -gt 0 ]; then
              exec ${pkgs.sone}/bin/sone "$@"
            fi
            exec ${config.programs.umbriel.package}/bin/umbriel msg scratchpad-toggle sone
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
