{ ... }:
{
  den.aspects.workstation.wm.gtk = {
    homeManager =
      { pkgs, user, ... }:
      let
        t = user.theme;

        # Generated from user.theme; libadwaita reads these vars and re-skins
        # the active GTK theme (adwaita by default) without us shipping a
        # full theme package.
        colorCss = # css
          ''
            @define-color accent_color ${t.accent};
            @define-color accent_bg_color ${t.accent};
            @define-color accent_fg_color ${t.onAccent};

            @define-color destructive_color ${t.colors.red};
            @define-color success_color ${t.colors.green};
            @define-color warning_color ${t.colors.yellow};
            @define-color error_color ${t.colors.red};

            @define-color window_bg_color ${t.background};
            @define-color window_fg_color ${t.foreground};

            @define-color view_bg_color ${t.surface};
            @define-color view_fg_color ${t.foreground};

            @define-color card_bg_color ${t.surface};
            @define-color card_fg_color ${t.foreground};

            @define-color headerbar_bg_color ${t.elevated};
            @define-color headerbar_fg_color ${t.foreground};
            @define-color headerbar_border_color ${t.border};
            @define-color headerbar_backdrop_color ${t.surface};

            @define-color popover_bg_color ${t.elevated};
            @define-color popover_fg_color ${t.foreground};

            @define-color dialog_bg_color ${t.elevated};
            @define-color dialog_fg_color ${t.foreground};

            @define-color sidebar_bg_color ${t.surface};
            @define-color sidebar_fg_color ${t.foreground};
            @define-color sidebar_backdrop_bg_color ${t.background};

            @define-color secondary_sidebar_bg_color ${t.background};
            @define-color secondary_sidebar_fg_color ${t.foreground};

            @define-color tertiary_bg_color ${t.elevated};
            @define-color tertiary_fg_color ${t.foreground};
          '';

        # https://codeberg.org/river/wiki#how-do-i-disable-gtk-decorations-e-g-title-bar
        disableDecorations = {
          extraConfig = {
            gtk-dialogs-use-header = false;
          };
          extraCss = colorCss + # css
            ''
              /* No (default) title bar on wayland */
              headerbar.default-decoration {
                margin-bottom: 50px;
                margin-top: -100px;
              }

              /* rm -rf window shadows */
              window.csd,             /* gtk4? */
              window.csd decoration { /* gtk3 */
                box-shadow: none;
              }
            '';
        };
      in
      {
        home.packages = with pkgs; [
          papirus-icon-theme
        ];

        gtk = {
          enable = true;
          iconTheme = {
            name = "Papirus";
            package = pkgs.papirus-icon-theme;
          };
          gtk3 = disableDecorations;
          gtk4 = disableDecorations;
        };

        dconf = {
          enable = true;
          settings = {
            "org/gnome/desktop/interface" = {
              color-scheme = "prefer-dark";
              cursor-theme = "phinger-cursors-light";
            };
          };
        };
      };
  };
}
