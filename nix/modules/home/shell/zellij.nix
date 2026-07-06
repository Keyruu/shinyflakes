{ config, pkgs, lib, perSystem, ... }:
let
  fish = lib.getExe pkgs.fish;
  t = config.user.theme;
  navPlugin = "file:" + toString pkgs.zellijPlugins.vim-zellij-navigator;
in
{
  # Standalone scrollback viewer built via nix-wrapper-modules
  # (nix/packages/nvim-scrollback). Installed on PATH so zellij's
  # scrollback_editor can call it by absolute path.
  home.packages = [ perSystem.self.nvim-scrollback ];

  programs.zellij = {
    enable = true;
    extraConfig = # kdl
      ''
        theme "shiny"

        // Full UI-component theme built from config.user.theme. The
        // simplified fg/bg format auto-derives ribbon/frame colors badly;
        // mapping each component explicitly keeps the palette consistent.
        themes {
          shiny {
            text_unselected {
              base "${t.foreground}"
              background "${t.background}"
              emphasis_0 "${t.colors.orange}"
              emphasis_1 "${t.colors.cyan}"
              emphasis_2 "${t.colors.green}"
              emphasis_3 "${t.colors.magenta}"
            }
            text_selected {
              base "${t.foreground}"
              background "${t.muted}"
              emphasis_0 "${t.colors.orange}"
              emphasis_1 "${t.colors.cyan}"
              emphasis_2 "${t.colors.green}"
              emphasis_3 "${t.colors.magenta}"
            }
            ribbon_selected {
              base "${t.onAccent}"
              background "${t.accent}"
              emphasis_0 "${t.colors.red}"
              emphasis_1 "${t.colors.orange}"
              emphasis_2 "${t.colors.magenta}"
              emphasis_3 "${t.colors.blue}"
            }
            ribbon_unselected {
              base "${t.foreground}"
              background "${t.surface}"
              emphasis_0 "${t.colors.red}"
              emphasis_1 "${t.foreground}"
              emphasis_2 "${t.accent}"
              emphasis_3 "${t.colors.magenta}"
            }
            table_title {
              base "${t.accent}"
              background "${t.background}"
              emphasis_0 "${t.colors.orange}"
              emphasis_1 "${t.colors.cyan}"
              emphasis_2 "${t.colors.green}"
              emphasis_3 "${t.colors.magenta}"
            }
            table_cell_selected {
              base "${t.foreground}"
              background "${t.muted}"
              emphasis_0 "${t.colors.orange}"
              emphasis_1 "${t.colors.cyan}"
              emphasis_2 "${t.colors.green}"
              emphasis_3 "${t.colors.magenta}"
            }
            table_cell_unselected {
              base "${t.foreground}"
              background "${t.background}"
              emphasis_0 "${t.colors.orange}"
              emphasis_1 "${t.colors.cyan}"
              emphasis_2 "${t.colors.green}"
              emphasis_3 "${t.colors.magenta}"
            }
            list_selected {
              base "${t.foreground}"
              background "${t.muted}"
              emphasis_0 "${t.colors.orange}"
              emphasis_1 "${t.colors.cyan}"
              emphasis_2 "${t.colors.green}"
              emphasis_3 "${t.colors.magenta}"
            }
            list_unselected {
              base "${t.foreground}"
              background "${t.background}"
              emphasis_0 "${t.colors.orange}"
              emphasis_1 "${t.colors.cyan}"
              emphasis_2 "${t.colors.green}"
              emphasis_3 "${t.colors.magenta}"
            }
            frame_selected {
              base "${t.accent}"
              background "${t.background}"
              emphasis_0 "${t.colors.orange}"
              emphasis_1 "${t.colors.cyan}"
              emphasis_2 "${t.colors.magenta}"
              emphasis_3 "${t.background}"
            }
            frame_highlight {
              base "${t.colors.orange}"
              background "${t.background}"
              emphasis_0 "${t.colors.magenta}"
              emphasis_1 "${t.colors.orange}"
              emphasis_2 "${t.colors.orange}"
              emphasis_3 "${t.colors.orange}"
            }
            exit_code_success {
              base "${t.colors.green}"
              background "${t.background}"
              emphasis_0 "${t.colors.cyan}"
              emphasis_1 "${t.background}"
              emphasis_2 "${t.colors.magenta}"
              emphasis_3 "${t.accent}"
            }
            exit_code_error {
              base "${t.colors.red}"
              background "${t.background}"
              emphasis_0 "${t.colors.yellow}"
              emphasis_1 "${t.background}"
              emphasis_2 "${t.background}"
              emphasis_3 "${t.background}"
            }
            multiplayer_user_colors {
              player_1 "${t.colors.magenta}"
              player_2 "${t.accent}"
              player_3 "${t.background}"
              player_4 "${t.colors.yellow}"
              player_5 "${t.colors.cyan}"
              player_6 "${t.background}"
              player_7 "${t.colors.red}"
              player_8 "${t.background}"
              player_9 "${t.background}"
              player_10 "${t.background}"
            }
          }
        }

        config {
          default_shell "${fish}"
          scrollback_editor "${lib.getExe perSystem.self.nvim-scrollback}"
        }

        // Built-in tmux mode mirrors the tmux prefix workflow: c/z/x/d/n/p/,
        // and h/j/k/l pane nav. Prefix is moved from Ctrl-b to Ctrl-Space to
        // match the tmux muscle memory. Splits use - (stacked) and | (side)
        // alongside the default " / %, and f toggles floating panes.
        keybinds {
          shared_except "tmux" "locked" {
            unbind "Ctrl b"
            bind "Ctrl Space" { SwitchToMode "Tmux"; }
            // Ctrl-b freed by the prefix move → reuse for Move mode
            // (Ctrl-m can't be used: it's the same byte as Enter).
            bind "Ctrl b" { SwitchToMode "Move"; }
          }

          tmux {
            unbind "Ctrl b"
            // Ctrl-Space twice sends a literal Ctrl-Space (NUL) through.
            bind "Ctrl Space" { Write 0; SwitchToMode "Normal"; }
            bind "-" { NewPane "Down"; SwitchToMode "Normal"; }
            bind "|" { NewPane "Right"; SwitchToMode "Normal"; }
            bind "f" { ToggleFloatingPanes; SwitchToMode "Normal"; }
            bind "v" { EditScrollback ansi=true; SwitchToMode "Normal"; }
          }

          // Smart Ctrl+hjkl: vim-zellij-navigator forwards to nvim splits and
          // hands off to zellij panes (or tabs) at the edge. nvim side needs
          // smart-splits with zellij auto-detection — not wired yet, testing
          // the zellij half first.
          shared_except "locked" {
            bind "Ctrl h" {
              MessagePlugin "${navPlugin}" {
                name "move_focus_or_tab"
                payload "left"
                move_mod "ctrl"
              }
            }
            bind "Ctrl j" {
              MessagePlugin "${navPlugin}" {
                name "move_focus"
                payload "down"
                move_mod "ctrl"
              }
            }
            bind "Ctrl k" {
              MessagePlugin "${navPlugin}" {
                name "move_focus"
                payload "up"
                move_mod "ctrl"
              }
            }
            bind "Ctrl l" {
              MessagePlugin "${navPlugin}" {
                name "move_focus_or_tab"
                payload "right"
                move_mod "ctrl"
              }
            }
          }
        }
      '';
  };

  xdg.configFile = {
    # Dev layout mirrors the tmux default-layout script: window "edit" with
    # the editor + a 30% bottom term on the left, and a 40% pi pane on the
    # right. split_direction "vertical" = side-by-side, "horizontal" = stacked.
    "zellij/layouts/default.kdl".text =
      # kdl
      ''
        layout {
          pane size=1 borderless=true {
            plugin location="zellij:tab-bar"
          }

          pane split_direction="vertical" {
            pane split_direction="horizontal" {
              pane
              pane size="30%"
            }
            pane size="40%"
          }

          pane size=1 borderless=true {
            plugin location="zellij:status-bar"
          }

          floating_panes {
            pane command="lazygit"
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

          pane split_direction="vertical" {
            pane split_direction="horizontal" {
              pane command="nvim" {
                args "."
                cwd "~/shinyflakes"
              }
              pane size="30%"
            }
            pane size="40%"
          }

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
