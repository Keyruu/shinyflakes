{ ... }:
{
  den.aspects.shell.zellij = {
    homeManager =
      {
        config,
        user,
        pkgs,
        lib,
        self',
        ...
      }:
      let
        fish = lib.getExe pkgs.fish;
        t = user.theme;
        navPlugin = "file:" + toString pkgs.zellijPlugins.vim-zellij-navigator;
      in
      {
        home.packages = [
          self'.packages.nvim-scrollback
          self'.packages.pi-herd
        ];

        # Zellij live-reloads config via an mtime-polling watcher that follows
        # symlinks. Nix store files all have epoch mtime, so HM's symlink swap on
        # rebuild never produces an mtime change and reload never fires. Replace
        # the symlink with a real copy (fresh mtime) after link generation;
        # force=true lets the next rebuild clobber the regular file.
        xdg.configFile."zellij/config.kdl".force = true;
        xdg.configFile."zellij/layouts/project.kdl".force = true;
        home.activation.zellijConfigCopy = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
          for cfg in "${config.xdg.configHome}/zellij/config.kdl" \
                     "${config.xdg.configHome}/zellij/layouts/project.kdl"; do
            if [ -L "$cfg" ]; then
              run cp --remove-destination "$(readlink -f "$cfg")" "$cfg"
              run chmod u+w "$cfg"
            fi
          done
        '';

        programs.zellij = {
          enable = true;
          extraConfig = # kdl
            ''
              theme "shiny"

              // Full UI-component theme built from user.theme. The
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

              default_mode "locked"
              default_shell "${fish}"
              scrollback_editor "${lib.getExe self'.packages.nvim-scrollback}"

              // Zellij's official "unlock-first" preset (from presets.rs),
              // adapted: unlock is Ctrl-Space (not Ctrl-g), secondary modifier
              // is Super (not Alt — that's the WM mod), and Normal additionally
              // carries tmux-style direct action binds. Every action returns to
              // Locked; clear-defaults avoids the built-in binds that return to
              // Normal instead.
              keybinds clear-defaults=true {
                locked {
                  bind "Ctrl Space" { SwitchToMode "Normal"; }
                }

                normal {
                  bind "c" { NewTab; SwitchToMode "Locked"; }
                  bind "x" { CloseFocus; SwitchToMode "Locked"; }
                  bind "z" { ToggleFocusFullscreen; SwitchToMode "Locked"; }
                  bind "d" { Detach; }
                  bind "h" { MoveFocus "Left"; SwitchToMode "Locked"; }
                  bind "j" { MoveFocus "Down"; SwitchToMode "Locked"; }
                  bind "k" { MoveFocus "Up"; SwitchToMode "Locked"; }
                  bind "l" { MoveFocus "Right"; SwitchToMode "Locked"; }
                  bind "-" { NewPane "Down"; SwitchToMode "Locked"; }
                  bind "|" { NewPane "Right"; SwitchToMode "Locked"; }
                  bind "f" { ToggleFloatingPanes; SwitchToMode "Locked"; }
                  bind "v" { EditScrollback { ansi true; }; SwitchToMode "Locked"; }
                  bind "D" {
                    OverrideLayout {
                      layout "project";
                      apply_only_to_active_tab true;
                    }; SwitchToMode "Locked";
                  }
                }

                pane {
                  bind "p" { SwitchToMode "Normal"; }
                  bind "h" "Left" { MoveFocus "Left"; }
                  bind "l" "Right" { MoveFocus "Right"; }
                  bind "j" "Down" { MoveFocus "Down"; }
                  bind "k" "Up" { MoveFocus "Up"; }
                  bind "Tab" { SwitchFocus; }
                  bind "n" { NewPane; SwitchToMode "Locked"; }
                  bind "d" { NewPane "Down"; SwitchToMode "Locked"; }
                  bind "r" { NewPane "Right"; SwitchToMode "Locked"; }
                  bind "s" { NewPane "stacked"; SwitchToMode "Locked"; }
                  bind "x" { CloseFocus; SwitchToMode "Locked"; }
                  bind "f" { ToggleFocusFullscreen; SwitchToMode "Locked"; }
                  bind "z" { TogglePaneFrames; SwitchToMode "Locked"; }
                  bind "w" { ToggleFloatingPanes; SwitchToMode "Locked"; }
                  bind "e" { TogglePaneEmbedOrFloating; SwitchToMode "Locked"; }
                  bind "c" { SwitchToMode "RenamePane"; PaneNameInput 0; }
                  bind "i" { TogglePanePinned; SwitchToMode "Locked"; }
                }

                move {
                  bind "m" { SwitchToMode "Normal"; }
                  bind "n" "Tab" { MovePane; }
                  bind "p" { MovePaneBackwards; }
                  bind "h" "Left" { MovePane "Left"; }
                  bind "j" "Down" { MovePane "Down"; }
                  bind "k" "Up" { MovePane "Up"; }
                  bind "l" "Right" { MovePane "Right"; }
                }

                tab {
                  bind "t" { SwitchToMode "Normal"; }
                  bind "r" { SwitchToMode "RenameTab"; TabNameInput 0; }
                  bind "h" "Left" "Up" "k" { GoToPreviousTab; }
                  bind "l" "Right" "Down" "j" { GoToNextTab; }
                  bind "n" { NewTab; SwitchToMode "Locked"; }
                  bind "x" { CloseTab; SwitchToMode "Locked"; }
                  bind "s" { ToggleActiveSyncTab; SwitchToMode "Locked"; }
                  bind "b" { BreakPane; SwitchToMode "Locked"; }
                  bind "]" { BreakPaneRight; SwitchToMode "Locked"; }
                  bind "[" { BreakPaneLeft; SwitchToMode "Locked"; }
                  bind "1" { GoToTab 1; SwitchToMode "Locked"; }
                  bind "2" { GoToTab 2; SwitchToMode "Locked"; }
                  bind "3" { GoToTab 3; SwitchToMode "Locked"; }
                  bind "4" { GoToTab 4; SwitchToMode "Locked"; }
                  bind "5" { GoToTab 5; SwitchToMode "Locked"; }
                  bind "6" { GoToTab 6; SwitchToMode "Locked"; }
                  bind "7" { GoToTab 7; SwitchToMode "Locked"; }
                  bind "8" { GoToTab 8; SwitchToMode "Locked"; }
                  bind "9" { GoToTab 9; SwitchToMode "Locked"; }
                  bind "Tab" { ToggleTab; }
                }

                resize {
                  bind "r" { SwitchToMode "Normal"; }
                  bind "h" "Left" { Resize "Increase Left"; }
                  bind "j" "Down" { Resize "Increase Down"; }
                  bind "k" "Up" { Resize "Increase Up"; }
                  bind "l" "Right" { Resize "Increase Right"; }
                  bind "H" { Resize "Decrease Left"; }
                  bind "J" { Resize "Decrease Down"; }
                  bind "K" { Resize "Decrease Up"; }
                  bind "L" { Resize "Decrease Right"; }
                  bind "=" "+" { Resize "Increase"; }
                  bind "-" { Resize "Decrease"; }
                }

                scroll {
                  bind "s" { SwitchToMode "Normal"; }
                  bind "e" { EditScrollback { ansi true; }; SwitchToMode "Locked"; }
                  bind "f" { SwitchToMode "EnterSearch"; SearchInput 0; }
                  bind "Ctrl c" { ScrollToBottom; SwitchToMode "Locked"; }
                  bind "j" "Down" { ScrollDown; }
                  bind "k" "Up" { ScrollUp; }
                  bind "Ctrl f" "PageDown" "Right" "l" { PageScrollDown; }
                  bind "Ctrl b" "PageUp" "Left" "h" { PageScrollUp; }
                  bind "d" { HalfPageScrollDown; }
                  bind "u" { HalfPageScrollUp; }
                }

                search {
                  bind "Ctrl c" { ScrollToBottom; SwitchToMode "Locked"; }
                  bind "j" "Down" { ScrollDown; }
                  bind "k" "Up" { ScrollUp; }
                  bind "Ctrl f" "PageDown" "Right" "l" { PageScrollDown; }
                  bind "Ctrl b" "PageUp" "Left" "h" { PageScrollUp; }
                  bind "d" { HalfPageScrollDown; }
                  bind "u" { HalfPageScrollUp; }
                  bind "n" { Search "down"; }
                  bind "p" { Search "up"; }
                  bind "c" { SearchToggleOption "CaseSensitivity"; }
                  bind "w" { SearchToggleOption "Wrap"; }
                  bind "o" { SearchToggleOption "WholeWord"; }
                }

                entersearch {
                  bind "Ctrl c" "Esc" { SwitchToMode "Scroll"; }
                  bind "Enter" { SwitchToMode "Search"; }
                }

                renametab {
                  bind "Ctrl c" "Enter" { SwitchToMode "Locked"; }
                  bind "Esc" { UndoRenameTab; SwitchToMode "Tab"; }
                }

                renamepane {
                  bind "Ctrl c" "Enter" { SwitchToMode "Locked"; }
                  bind "Esc" { UndoRenamePane; SwitchToMode "Pane"; }
                }

                session {
                  bind "o" { SwitchToMode "Normal"; }
                  bind "d" { Detach; }
                  bind "w" {
                    LaunchOrFocusPlugin "session-manager" {
                      in_place true
                    };
                    SwitchToMode "Locked"
                  }
                  bind "c" {
                    LaunchOrFocusPlugin "configuration" {
                      floating true
                      move_to_focused_tab true
                    };
                    SwitchToMode "Locked"
                  }
                  bind "p" {
                    LaunchOrFocusPlugin "plugin-manager" {
                      floating true
                      move_to_focused_tab true
                    };
                    SwitchToMode "Locked"
                  }
                  bind "l" {
                    LaunchOrFocusPlugin "zellij:layout-manager" {
                      floating true
                      move_to_focused_tab true
                    };
                    SwitchToMode "Locked"
                  }
                }

                shared_except "locked" "renametab" "renamepane" {
                  bind "Ctrl Space" { SwitchToMode "Locked"; }
                  bind "Ctrl q" { Quit; }
                  bind "Enter" { SwitchToMode "Locked"; }
                }

                shared_except "renamepane" "renametab" "entersearch" "locked" {
                  bind "Esc" { SwitchToMode "Locked"; }
                }

                // bare mode switches, reachable from Normal and other modes
                shared_except "pane" "locked" "renametab" "renamepane" "entersearch" {
                  bind "p" { SwitchToMode "Pane"; }
                }
                shared_except "resize" "locked" "renametab" "renamepane" "entersearch" {
                  bind "r" { SwitchToMode "Resize"; }
                }
                shared_except "scroll" "locked" "renametab" "renamepane" "entersearch" {
                  bind "s" { SwitchToMode "Scroll"; }
                }
                shared_except "session" "locked" "renametab" "renamepane" "entersearch" {
                  bind "o" { SwitchToMode "Session"; }
                }
                shared_except "tab" "locked" "renametab" "renamepane" "entersearch" {
                  bind "t" { SwitchToMode "Tab"; }
                }
                shared_except "move" "locked" "renametab" "renamepane" "entersearch" {
                  bind "m" { SwitchToMode "Move"; }
                }

                // shared: quick binds must also work while locked, since locked
                // is the default state.
                shared {
                  // Secondary modifier is Super instead of zellij's default Alt
                  // (Alt is the WM mod). Needs kitty keyboard protocol — foot,
                  // ghostty and kitty all support it.
                  bind "Super h" { GoToPreviousTab; }
                  bind "Super l" { GoToNextTab; }
                  bind "Super n" { NewPane; }
                  bind "Super f" { ToggleFloatingPanes; }
                  // pi instance overview — jump to any pi across sessions
                  bind "Super p" {
                    Run "${lib.getExe self'.packages.pi-herd}" {
                      floating true
                      close_on_exit true
                      name "pi herd"
                    }
                  }
                  bind "Super s" {
                    Run "${lib.getExe self'.packages.zs}" {
                      floating true
                      close_on_exit true
                      name "zs"
                    }
                  }
                  bind "Super i" { MoveTab "Left"; }
                  bind "Super o" { MoveTab "Right"; }
                  bind "Super =" "Super +" { Resize "Increase"; }
                  bind "Super -" { Resize "Decrease"; }
                  // re-apply swap layout — snaps the floating lazygit pane back
                  // to 80% after a monitor/terminal resize (floating pane sizes
                  // are only computed at spawn)
                  bind "Super [" { PreviousSwapLayout; }
                  bind "Super ]" { NextSwapLayout; }
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
          "zellij/layouts/project.kdl".text =
            # kdl
            ''
              layout {
                // template so NewTab-created tabs also get both bars
                default_tab_template {
                  pane size=1 borderless=true {
                    plugin location="zellij:tab-bar"
                  }
                  children
                  pane size=1 borderless=true {
                    plugin location="zellij:status-bar"
                  }
                }

                tab hide_floating_panes=true {
                  pane split_direction="vertical" {
                    pane split_direction="horizontal" {
                      pane command="nvim"
                      pane size="30%"
                    }
                    pane command="pi" size="40%"
                  }

                  floating_panes {
                    pane command="lazygit" {
                      width "80%"
                      height "80%"
                      x "10%"
                      y "10%"
                    }
                  }
                }

                // base swap layout for floating panes: Super ] re-applies these
                // percentages at the current terminal size after a monitor switch
                swap_floating_layout {
                  floating_panes {
                    pane {
                      width "80%"
                      height "80%"
                      x "10%"
                      y "10%"
                    }
                  }
                }
              }
            '';
        };
      };
  };
}
