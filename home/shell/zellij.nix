{pkgs, ...}: {
  home.packages = with pkgs; [
    zellij
  ];

  home.file.".config/zellij/config.kdl".text =
    /*
    kdl
    */
    ''
      keybinds {
        pane {
          bind "g" {
            Run "zellij" "run" "-f" "-c" "--" "lazygit" {
              close_on_exit true
            };
          }
        }
      }
    '';

  home.file.".config/zellij/layouts/nix.kdl".text =
    /*
    kdl
    */
    ''
      layout {
        pane size=1 borderless=true {
          plugin location="zellij:tab-bar"
        }
        pane split_direction="horizontal" {
          pane command="vi" size="70%" {
            args "."
            cwd "~/shinyflakes"
          }
          pane
        }
        pane size=2 borderless=true {
          plugin location="zellij:status-bar"
        }
        floating_panes {
          pane command="lazygit" {
            cwd "~/shinyflakes"
          }
        }
      }
    '';
}
