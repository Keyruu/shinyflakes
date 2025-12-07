{ config, pkgs, ... }:
{
  programs.helix = with pkgs; {
    enable = true;
    package = evil-helix;
    extraPackages = [
      astro-language-server
      bash-language-server
      biome
      clang-tools
      docker-compose-language-service
      dockerfile-language-server-nodejs
      golangci-lint
      golangci-lint-langserver
      gopls
      gotools
      marksman
      nil
      nixd
      nixpkgs-fmt
      nodePackages.prettier
      nodePackages.typescript-language-server
      sql-formatter
      ruff
      (python3.withPackages (
        p:
        (with p; [
          python-lsp-ruff
          python-lsp-server
        ])
      ))
      rust-analyzer
      taplo
      taplo-lsp
      terraform-ls
      typescript
      vscode-langservers-extracted
      yaml-language-server
    ];

    settings = {
      theme = "kanagawa";

      editor = {
        # Enable evil mode (vim keybindings)
        evil = true;

        # Visual and UI settings
        color-modes = true; # Evil-helix colors file types in statusline with this
        cursorline = true;
        bufferline = "multiple";
        line-number = "relative";
        rulers = [
          80
          120
        ];

        # Scrolloff matching your LazyVim config
        scrolloff = 999;

        # Cursor shapes (vim conventions)
        cursor-shape = {
          insert = "bar";
          normal = "block";
          select = "underline";
        };

        # Auto-save and formatting
        auto-save = {
          focus-lost = true;
          after-delay.enable = true;
        };
        auto-format = true;

        # File picker settings
        file-picker = {
          hidden = false;
          ignore = true;
          git-ignore = true;
          git-global = true;
          git-exclude = true;
        };

        # Indentation guides (evil-helix supports colored/rainbow guides)
        indent-guides = {
          render = true;
          character = "│";
          skip-levels = 1;
          rainbow-option = "dim"; # Evil-helix rainbow indentation
        };

        # Soft wrap
        soft-wrap = {
          enable = true;
          wrap-at-text-width = true;
        };

        # Diagnostics display
        end-of-line-diagnostics = "hint";
        inline-diagnostics.cursor-line = "warning";

        # LSP features
        lsp = {
          display-messages = true;
          display-inlay-hints = true;
          display-signature-help-docs = true;
          snippets = true;
          goto-reference-include-declaration = true;
        };

        # Mouse support
        mouse = true;

        # Smart tab disabled by default in evil-helix
        smart-tab.enable = false;

        # Statusline configuration
        statusline = {
          left = [
            "mode"
            "spinner"
            "file-name"
            "read-only-indicator"
            "file-modification-indicator"
          ];
          center = [ "diagnostics" ];
          right = [
            "selections"
            "primary-selection-length"
            "position"
            "position-percentage"
            "file-encoding"
            "file-line-ending"
            "file-type"
          ];
          separator = "│";
          mode = {
            normal = "NOR";
            insert = "INS";
            select = "VIS"; # Evil-helix renames SEL to VIS
          };
        };

        # Search configuration
        search = {
          smart-case = true;
          wrap-around = true;
        };

        # Whitespace rendering
        whitespace = {
          render = {
            space = "none";
            tab = "all";
            newline = "none";
          };
          characters = {
            space = "·";
            nbsp = "⍽";
            tab = "→";
            newline = "⏎";
            tabpad = "·";
          };
        };
      };

      # With evil-helix, you get vim keybindings by default, so we only need
      # to add custom mappings that aren't part of standard vim
      keys = {
        normal = {
          # Leader key mappings (these supplement vim bindings)
          space = {
            # File operations
            w = ":write";
            q = ":quit";
            Q = ":quit!";
            x = ":write-quit";
            X = ":write-quit-all";

            # File picker and search (LazyVim-like)
            f = {
              f = "file_picker";
              r = "file_picker_in_current_buffer_directory";
              g = "global_search";
              b = "buffer_picker";
              h = "select_references_to_symbol_under_cursor";
              s = "symbol_picker";
              S = "workspace_symbol_picker";
              d = "diagnostics_picker";
              D = "workspace_diagnostics_picker";
            };

            # LSP operations
            l = {
              r = "rename_symbol";
              a = "code_action";
              h = "hover";
              s = "signature_help";
              d = "goto_definition";
              D = "goto_declaration";
              i = "goto_implementation";
              t = "goto_type_definition";
              R = "goto_references";
              f = ":format";
            };

            # Git operations
            g = {
              s = ":toggle-option diff-gutter";
              b = ":reset-diff-change";
              n = "goto_next_change";
              p = "goto_prev_change";
            };

            # Diagnostics
            e = "goto_next_diag";
            E = "goto_prev_diag";

            # Toggle options
            o = {
              w = ":toggle soft-wrap.enable";
              n = ":toggle line-numbers";
              r = ":toggle relative-line-numbers";
              i = ":toggle lsp.display-inlay-hints";
              d = ":toggle lsp.display-messages";
            };

            # System clipboard (matching LazyVim)
            y = "yank_to_clipboard";
            p = "paste_clipboard_after";
            P = "paste_clipboard_before";
          };

          # Quick LSP actions (vim-style with 'g' prefix)
          g = {
            d = "goto_definition";
            D = "goto_declaration";
            i = "goto_implementation";
            t = "goto_type_definition";
            r = "goto_references";
            h = "hover";
          };

          # Window navigation (keep these for muscle memory)
          C-h = "jump_view_left";
          C-j = "jump_view_down";
          C-k = "jump_view_up";
          C-l = "jump_view_right";

          # Tab navigation for buffers
          tab = "goto_next_buffer";
          S-tab = "goto_previous_buffer";
        };

        # Insert mode additions
        insert = {
          # Common vim escape sequences
          j.k = "normal_mode";
          j.j = "normal_mode";

          # Clipboard in insert
          C-v = "paste_clipboard_after";
        };

        # Visual/Select mode additions
        select = {
          # System clipboard in visual mode
          space.y = "yank_to_clipboard";
          space.p = "replace_selections_with_clipboard";
        };
      };
    };

    themes = {
      # Kanagawa theme (matching your LazyVim kanagawa plugin)
      kanagawa = {
        inherits = "kanagawa";
        "ui.background" = { };
      };

      # Keep gruvbox as fallback
      gruvbox_community = {
        inherits = "gruvbox";
        "variable" = "blue1";
        "variable.parameter" = "blue1";
        "function.macro" = "red1";
        "operator" = "orange1";
        "comment" = "gray";
        "constant.builtin" = "orange1";
        "ui.background" = { };
      };
    };

    languages = {
      language-server = {
        biome = {
          command = "biome";
          args = [ "lsp-proxy" ];
        };

        rust-analyzer.config.check = {
          command = "clippy";
        };

        yaml-language-server.config.yaml.schemas = {
          kubernetes = "k8s/*.yaml";
        };

        typescript-language-server.config.tsserver = {
          path = "${pkgs.typescript}/lib/node_modules/typescript/lib/tsserver.js";
        };
      };

      language = [
        {
          name = "astro";
          language-servers = [
            {
              name = "typescript-language-server";
              except-features = [ "format" ];
            }
            "biome"
            "astro-language-server"
          ];
          auto-format = true;
        }
        {
          name = "css";
          language-servers = [ "vscode-css-language-server" ];
          formatter = {
            command = "prettier";
            args = [
              "--stdin-filepath"
              "file.css"
            ];
          };
          auto-format = true;
        }
        {
          name = "go";
          language-servers = [
            "gopls"
            "golangci-lint-lsp"
          ];
          formatter = {
            command = "goimports";
          };
          auto-format = true;
        }
        {
          name = "html";
          language-servers = [ "vscode-html-language-server" ];
          formatter = {
            command = "prettier";
            args = [
              "--stdin-filepath"
              "file.html"
            ];
          };
          auto-format = true;
        }
        {
          name = "javascript";
          language-servers = [
            {
              name = "typescript-language-server";
              except-features = [ "format" ];
            }
            "biome"
          ];
          auto-format = true;
        }
        {
          name = "json";
          language-servers = [
            {
              name = "vscode-json-language-server";
              except-features = [ "format" ];
            }
            "biome"
          ];
          formatter = {
            command = "biome";
            args = [
              "format"
              "--indent-style"
              "space"
              "--stdin-file-path"
              "file.json"
            ];
          };
          auto-format = true;
        }
        {
          name = "jsonc";
          language-servers = [
            {
              name = "vscode-json-language-server";
              except-features = [ "format" ];
            }
            "biome"
          ];
          formatter = {
            command = "biome";
            args = [
              "format"
              "--indent-style"
              "space"
              "--stdin-file-path"
              "file.jsonc"
            ];
          };
          file-types = [
            "jsonc"
            "hujson"
          ];
          auto-format = true;
        }
        {
          name = "jsx";
          language-servers = [
            {
              name = "typescript-language-server";
              except-features = [ "format" ];
            }
            "biome"
          ];
          formatter = {
            command = "biome";
            args = [
              "format"
              "--indent-style"
              "space"
              "--stdin-file-path"
              "file.jsx"
            ];
          };
          auto-format = true;
        }
        {
          name = "markdown";
          language-servers = [ "marksman" ];
          formatter = {
            command = "prettier";
            args = [
              "--stdin-filepath"
              "file.md"
            ];
          };
          auto-format = true;
        }
        {
          name = "nix";
          formatter = {
            command = "nixpkgs-fmt";
          };
          auto-format = true;
        }
        {
          name = "python";
          language-servers = [ "pylsp" ];
          formatter = {
            command = "sh";
            args = [
              "-c"
              "ruff check --select I --fix - | ruff format --line-length 88 -"
            ];
          };
          auto-format = true;
        }
        {
          name = "rust";
          language-servers = [ "rust-analyzer" ];
          auto-format = true;
        }
        {
          name = "scss";
          language-servers = [ "vscode-css-language-server" ];
          formatter = {
            command = "prettier";
            args = [
              "--stdin-filepath"
              "file.scss"
            ];
          };
          auto-format = true;
        }
        {
          name = "sql";
          language-servers = [ ];
          formatter = {
            command = "sql-formatter";
            args = [
              "-l"
              "postgresql"
              "-c"
              "{\"keywordCase\": \"lower\", \"dataTypeCase\": \"lower\", \"functionCase\": \"lower\", \"expressionWidth\": 120, \"tabWidth\": 4}"
            ];
          };
          auto-format = true;
        }
        {
          name = "toml";
          language-servers = [ "taplo" ];
          formatter = {
            command = "taplo";
            args = [
              "fmt"
              "-o"
              "column_width=120"
              "-"
            ];
          };
          auto-format = true;
        }
        {
          name = "tsx";
          language-servers = [
            {
              name = "typescript-language-server";
              except-features = [ "format" ];
            }
            "biome"
          ];
          formatter = {
            command = "biome";
            args = [
              "format"
              "--indent-style"
              "space"
              "--stdin-file-path"
              "file.tsx"
            ];
          };
          auto-format = true;
        }
        {
          name = "typescript";
          language-servers = [
            {
              name = "typescript-language-server";
              except-features = [ "format" ];
            }
            "biome"
          ];
          formatter = {
            command = "biome";
            args = [
              "format"
              "--indent-style"
              "space"
              "--stdin-file-path"
              "file.ts"
            ];
          };
          auto-format = true;
        }
        {
          name = "yaml";
          language-servers = [ "yaml-language-server" ];
          formatter = {
            command = "prettier";
            args = [
              "--stdin-filepath"
              "file.yaml"
            ];
          };
          auto-format = true;
        }
      ];
    };
  };
}
