{ config, ... }:
{
  programs.zed-editor = {
    enable = true;

    extensions = [
      "material-icon-theme"
      "nix"
      "helm"
      "scala"
      "git-firefly"
    ];

    userSettings = {
      tab_bar = {
        show = true;
      };
      telemetry = {
        diagnostics = false;
        metrics = false;
      };
      theme = "Colorizer";
      edit_predictions = {
        mode = "subtle";
      };
      ui_font_family = "JetBrainsMono Nerd Font";
      terminal = {
        dock = "bottom";
        font_family = "JetBrainsMono Nerd Font";
      };
      icon_theme = "Material Icon Theme";
      features = {
        edit_prediction_provider = "zed";
      };
      tabs = {
        file_icons = true;
        git_status = true;
      };
      active_pane_modifiers = {
        border_size = 1;
      };
      cursor_blink = false;
      vim_mode = true;
      relative_line_numbers = true;
      ui_font_size = 14;
      buffer_font_size = 14;
      vim = {
        use_system_clipboard = "on_yank";
      };
      inlay_hints = {
        enabled = true;
      };
      languages = {
        Scala = {
          language_servers = [
            "metals"
            "tailwindcss-language-server"
          ];
        };
        Nix = {
          language_servers = [
            "nixd"
            "!nil"
          ];
        };
      };
      lsp = {
        nixd = {
          settings = {
            nixpkgs = {
              expr = "import <nixpkgs> {}";
            };
            formatting = {
              command = "nixfmt";
            };
            options = {
              nixos = {
                expr = "(builtins.getFlake \"${config.home.homeDirectory}/shinyflakes\").nixosConfigurations.sleipnir.options";
              };
              home-manager = {
                expr = "(builtins.getFlake \"${config.home.homeDirectory}/shinyflakes\").homeConfigurations.\"lucas@thopter\".options";
              };
              nix-darwin = {
                expr = "(builtins.getFlake \"${config.home.homeDirectory}/shinyflakes\").darwinConfigurations.stern.options";
              };
            };
            diagnostic = {
              suppress = [ "sema-extra-with" ];
            };
          };
        };
        metals = {
          settings = {
            inlayHints = {
              inferredTypes = {
                enable = true;
              };
            };
            binary = {
              arguments = [ "-Dmetals.http=on" ];
            };
            initialization_options = {
              isHttpEnabled = true;
            };
          };
        };
        tailwindcss-language-server = {
          settings = {
            includeLanguages = {
              scala = "html";
            };
            classAttributes = [
              "class"
              "className"
              "cls"
            ];
            experimental = {
              classRegex = [
                "cls\\s*:\\=\\s*['\"`]([^'\"`]*)['\"`]"
                "className\\s*:\\=\\s*['\"`]([^'\"`]*)['\"`]"
                [
                  "cls\\s*:\\=\\s*\"\"\"([\\s\\S]*?)\"\"\""
                  1
                ]
              ];
            };
          };
        };
      };
    };

    userKeymaps = [
      {
        context = "(Editor && vim_mode) || Dock || Terminal";
        bindings = {
          "ctrl-h" = "workspace::ActivatePaneLeft";
          "ctrl-j" = "workspace::ActivatePaneDown";
          "ctrl-k" = "workspace::ActivatePaneUp";
          "ctrl-l" = "workspace::ActivatePaneRight";
        };
      }
      {
        context = "Editor && !vim_mode";
        bindings = {
          "ctrl-j" = "editor::MoveDown";
          "ctrl-k" = "editor::MoveUp";
          "ctrl-y" = [
            "workspace::SendKeystrokes"
            "enter"
          ];
        };
      }
      {
        context = "Editor && (vim_mode == normal || vim_mode == visual) && !VimWaiting && !menu";
        bindings = {
          # put key-bindings here if you want them to work in normal & visual mode
          # Git
          "space g h d" = "editor::ToggleSelectedDiffHunks";
          "space g s" = "git_panel::ToggleFocus";
          "space g g" = [
            "task::Spawn"
            { task_name = "lazygit"; }
          ];

          # Toggle inlay hints
          "space c i" = "editor::ToggleInlayHints";

          # Toggle soft wrap
          "space u w" = "editor::ToggleSoftWrap";

          # NOTE: Toggle Zen mode, not fully working yet
          "space c z" = "workspace::ToggleCenteredLayout";

          # Open markdown preview
          "space m p" = "markdown::OpenPreview";
          "space m P" = "markdown::OpenPreviewToTheSide";

          # Open recent project
          "space f p" = "projects::OpenRecent";
          # Search word under cursor
          # "space f g" = "pane::DeploySearch";
          "space f g" = [
            "task::Spawn"
            { task_name = "tv-text"; }
          ];
          "space f f" = "file_finder::Toggle";

          "-" = [
            "task::Spawn"
            { task_name = "yazi"; }
          ];
          "_" = [
            "task::Spawn"
            { task_name = "yazi-root"; }
          ];

          # Chat with AI
          "space a c" = "agent::ToggleFocus";
          # Go to file with `gf`
          "g f" = "editor::OpenExcerpts";

          "space e" = "project_panel::ToggleFocus";
          "space t t" = "workspace::NewTerminal";
          "space t c" = "workspace::NewCenterTerminal";

          "space n v" = [
            "task::Spawn"
            { task_name = "nvim"; }
          ];
          "space n c" = "workspace::ClearAllNotifications";
        };
      }
      {
        context = "Editor && vim_mode == normal && !VimWaiting && !menu";
        bindings = {
          # put key-bindings here if you want them to work only in normal mode
          # Window movement bindings
          # Ctrl jklk to move between panes

          # +LSP
          "space c a" = "editor::ToggleCodeActions";
          "space ." = "editor::ToggleCodeActions";
          "space c r" = "editor::Rename";
          "g d" = "editor::GoToDefinition";
          "g D" = "editor::GoToDefinitionSplit";
          "g i" = "editor::GoToImplementation";
          "g I" = "editor::GoToImplementationSplit";
          "g t" = "editor::GoToTypeDefinition";
          "g T" = "editor::GoToTypeDefinitionSplit";
          "g r" = "editor::FindAllReferences";
          "] d" = "editor::GoToDiagnostic";
          "[ d" = "editor::GoToPreviousDiagnostic";
          # TODO: Go to next/prev error
          "] e" = "editor::GoToDiagnostic";
          "[ e" = "editor::GoToPreviousDiagnostic";
          # Symbol search
          "s s" = "outline::Toggle";
          "s S" = "project_symbols::Toggle";
          # Diagnostic
          "space x x" = "diagnostics::Deploy";

          # +Git
          # Git prev/next hunk
          "] h" = "editor::GoToHunk";
          "[ h" = "editor::GoToPreviousHunk";

          # TODO: git diff is not ready yet, refer https://github.com/zed-industries/zed/issues/8665#issuecomment-2194000497

          # + Buffers
          # Switch between buffers
          "shift-h" = "pane::ActivatePreviousItem";
          "shift-l" = "pane::ActivateNextItem";
          # Close active panel
          "shift-q" = "pane::CloseActiveItem";
          "ctrl-q" = "pane::CloseActiveItem";
          "space b d" = "pane::CloseActiveItem";
          # Close other items
          "space b o" = "pane::CloseOtherItems";
          # Save file
          "ctrl-s" = "workspace::Save";
          # File finder
          "space space" = "file_finder::Toggle";
          # Project search
          "space /" = "pane::DeploySearch";
          # TODO: Open other files
          # Show project panel with current file
          "space e" = "pane::RevealInProjectPanel";
        };
      }
      # Empty pane, set of keybindings that are available when there is no active editor
      {
        context = "EmptyPane || SharedScreen";
        bindings = {
          # Open file finder
          "space space" = "file_finder::Toggle";
          # Open recent project
          "space f p" = "projects::OpenRecent";
        };
      }
      # Rename
      {
        context = "Editor && vim_operator == c";
        bindings = {
          c = "vim::CurrentLine";
          r = "editor::Rename"; # zed specific
        };
      }
      # Code Action
      {
        context = "Editor && vim_operator == c";
        bindings = {
          c = "vim::CurrentLine";
          a = "editor::ToggleCodeActions"; # zed specific
        };
      }
      # File panel (netrw)
      {
        context = "ProjectPanel && not_editing";
        bindings = {
          a = "project_panel::NewFile";
          A = "project_panel::NewDirectory";
          r = "project_panel::Rename";
          d = "project_panel::Delete";
          x = "project_panel::Cut";
          c = "project_panel::Copy";
          p = "project_panel::Paste";
          # Close project panel as project file panel on the right
          q = "workspace::ToggleRightDock";
          "space e" = "workspace::ToggleRightDock";
        };
      }
      {
        context = "Workspace";
        bindings = {
          # Map VSCode like keybindings
          "cmd-b" = "workspace::ToggleRightDock";
        };
      }
      {
        context = "Terminal";
        bindings = {
          "; ;" = "terminal::ToggleViMode";
        };
      }
      {
        context = "Terminal && vi_mode";
        bindings = {
          q = "pane::CloseActiveItem";
          "shift-q" = "pane::CloseActiveItem";
          "shift-h" = "pane::ActivatePreviousItem";
          "shift-l" = "pane::ActivateNextItem";
        };
      }
      {
        context = "Editor && showing_completions";
        bindings = {
          "ctrl-y" = "editor::ConfirmCompletion";
          "ctrl-j" = "editor::ContextMenuNext";
          "ctrl-k" = "editor::ContextMenuPrevious";
        };
      }
      # Run nearest task
      {
        context = "EmptyPane || SharedScreen || vim_mode == normal";
        bindings = {
          "space r t" = [
            "editor::SpawnNearestTask"
            { reveal = "no_focus"; }
          ];
        };
      }
      # Sneak motion, refer https://github.com/zed-industries/zed/issues/22793/files#diff-90c0cb07588e2f309c31f0bb17096728b8f4e0bad71f3152d4d81ca867321c68
      {
        context = "vim_mode == normal || vim_mode == visual";
        bindings = {
          s = [
            "vim::PushSneak"
            { }
          ];
          S = [
            "vim::PushSneakBackward"
            { }
          ];
        };
      }
    ];

    userTasks = [
      {
        label = "lazygit";
        command = "lazygit -p $ZED_WORKTREE_ROOT";
        shell = {
          program = "sh";
        };
        hide = "always";
        reveal_target = "center";
      }
      {
        label = "yazi";
        command = "yazi $ZED_FILE";
        shell = {
          program = "sh";
        };
        hide = "always";
        reveal_target = "center";
      }
      {
        label = "yazi-root";
        command = "yazi $ZED_WORKTREE_ROOT";
        shell = {
          program = "sh";
        };
        hide = "always";
        reveal_target = "center";
      }
      {
        label = "nvim";
        command = "nvim $ZED_FILE";
        shell = {
          program = "sh";
        };
        hide = "always";
        reveal_target = "center";
      }
      {
        label = "nvim-root";
        command = "nvim $ZED_WORKTREE_ROOT";
        shell = {
          program = "sh";
        };
        hide = "always";
        reveal_target = "center";
      }
      {
        label = "tv-text";
        command = ''sel=$(tv text) && [ -n "$sel" ] && zeditor "$sel"'';
        shell = {
          program = "sh";
        };
        hide = "always";
        reveal_target = "center";
      }
    ];
  };
}
