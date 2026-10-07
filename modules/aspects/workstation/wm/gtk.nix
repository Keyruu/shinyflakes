{ ... }:
{
  den.aspects.workstation.wm.gtk = {
    homeManager =
      { pkgs, user, ... }:
      let
        t = user.theme;

        # Generated from user.theme; re-skins the active GTK theme (Adwaita)
        # via named colors for both GTK4 (window_bg_color etc.) and GTK3
        # (theme_bg_color etc. — used by xdg-desktop-portal-gtk dialogs).
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

            /* GTK3 Adwaita legacy names */
            @define-color theme_bg_color ${t.background};
            @define-color theme_fg_color ${t.foreground};
            @define-color theme_base_color ${t.surface};
            @define-color theme_text_color ${t.foreground};
            @define-color theme_selected_bg_color ${t.accent};
            @define-color theme_selected_fg_color ${t.onAccent};
            @define-color theme_unfocused_bg_color ${t.background};
            @define-color theme_unfocused_fg_color ${t.muted};
            @define-color theme_unfocused_base_color ${t.background};
            @define-color theme_unfocused_text_color ${t.muted};
            @define-color theme_unfocused_selected_bg_color ${t.surface};
            @define-color theme_unfocused_selected_fg_color ${t.foreground};
            @define-color borders ${t.border};
            @define-color unfocused_borders ${t.border};
            @define-color insensitive_bg_color ${t.background};
            @define-color insensitive_fg_color ${t.muted};
          '';

        # https://codeberg.org/river/wiki#how-do-i-disable-gtk-decorations-e-g-title-bar
        # GTK3 ignores dconf color-scheme, so without this the GTK3
        # xdg-desktop-portal-gtk dialogs (file picker) render light.
        disableDecorations = {
          extraConfig = {
            gtk-dialogs-use-header = false;
            gtk-application-prefer-dark-theme = true;
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
