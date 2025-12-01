{ pkgs, ... }:
{
  home = {
    pointerCursor = {
      package = pkgs.phinger-cursors;
      name = "phinger-cursors-light";
      size = 24;
      gtk.enable = true;
    };
    packages = with pkgs; [
      papirus-icon-theme
    ];
  };

  gtk =
    let
      # https://codeberg.org/river/wiki#how-do-i-disable-gtk-decorations-e-g-title-bar
      disableDecorations = {
        extraConfig = {
          gtk-dialogs-use-header = false;
        };
        extraCss = # css
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
      enable = true;
      theme = {
        name = "Dracula";
        package = pkgs.dracula-theme;
      };
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
      # Example for dark mode
      "org/gnome/desktop/interface" = {
        color-scheme = "prefer-dark";
        cursor-theme = "phinger-cursors-light";
      };
    };
  };
}
