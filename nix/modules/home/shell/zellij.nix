{ pkgs, lib, ... }:
let
  fish = lib.getExe pkgs.fish;
in
{
  programs.zellij = {
    enable = true;
    extraConfig = # kdl
      ''
        config {
          default_shell "${fish}"
        }

        keybinds {
          locked {
            bind "left_alt h" "SwitchWindow(direction: Left)"
            bind "left_alt l" "SwitchWindow(direction: Right)"
          }

          // --- Normal mode ---
          normal {
            bind "left_alt h" "SwitchWindow(direction: Left)"
            bind "left_alt l" "SwitchWindow(direction: Right)"
            bind "left_ctrl z" "SwitchToMode(mode: Pane)"
          }

          // --- Pane mode ---
          pane {
            bind "c" "NewTogglePane"
            bind "p" "NewTogglePane size: "50%" direction: "Right""
            bind "z" "ToggleFullscreen"
            bind "left_ctrl c" "SwitchToMode(mode: Normal)"
          }
        }
      '';
  };

  xdg.configFile = {
    "zellij/layouts/default.kdl".text =
      # kdl
      ''
        layout {
          // Top tab bar
          pane size=1 borderless=true {
            plugin location="zellij:tab-bar"
          }

          // Main content: editor (default command) + blank right pane
          pane split_direction="horizontal" {
            pane { }
            pane { }
          }

          // Bottom terminal bar (30%)
          pane size="30%" { }

          // Bottom status bar
          pane size=1 borderless=true {
            plugin location="zellij:status-bar"
          }

          // Floating panes available in this layout
          floating_panes {
            pane command="lazygit" { }
          }
        }
      '';

    "zellij/layouts/project.kdl".text =
      # kdl
      ''
        layout {
          pane size=1 borderless=true {
            plugin location="zellij:tab-bar"
          }

          pane split_direction="horizontal" {
            pane command="nvim" {
              args "."
              cwd "~/shinyflakes"
            }
            pane { }
          }

          pane size="30%" { }

          pane size=1 borderless=true {
            plugin location="zellij:status-bar"
          }

          floating_panes {
            pane command="lazygit" {
              cwd "~/shinyflakes"
            }
          }
        }
      '';
  };
}
