{ ... }:
{
  den.aspects.workstation.wm.qt = {
    homeManager =
      { pkgs, user, ... }:
      let
        t = user.theme;

        # qt6ct reads ~/.config/qt6ct/colors.conf only when QT_QPA_PLATFORMTHEME
        # points at it; without the env var Qt apps ignore the file.
        colorsConf = # ini
          ''
            [ColorScheme]
            activeBackground=${t.elevated}
            activeForeground=${t.foreground}
            disabledBackground=${t.background}
            disabledForeground=${t.muted}
            inactiveBackground=${t.surface}
            inactiveForeground=${t.muted}

            [General]
            alternateBackground=${t.surface}
            background=${t.background}
            borderColor=${t.border}
            button=${t.elevated}
            buttonText=${t.foreground}
            dark=${t.background}
            focus=${t.accent}
            foreground=${t.foreground}
            highlight=${t.accent}
            highlightedText=${t.onAccent}
            light=${t.elevated}
            link=${t.accent}
            mid=${t.border}
            midlight=${t.border}
            placeholderText=${t.muted}
            shadow=${t.background}
            text=${t.foreground}
            toolTipBase=${t.surface}
            toolTipText=${t.foreground}
            window=${t.background}
            windowText=${t.foreground}
          '';
      in
      {
        home.sessionVariables.QT_QPA_PLATFORMTHEME = "qt6ct";

        home.packages = [ pkgs.qt6Packages.qt6ct ];

        xdg.configFile."qt6ct/colors.conf".text = colorsConf;
      };
  };
}