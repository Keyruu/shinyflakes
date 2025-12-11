_:
{
  programs.television = {
    enable = true;
    enableFishIntegration = false;

    settings = {
      ui = {
        use_nerd_font_icons = true;
        show_preview_panel = true;
      };
    };

    channels = {
      files = {
        metadata = {
          name = "files";
          description = "A channel to select files and directories";
          requirements = [
            "fd"
            "bat"
          ];
        };
        source.command = "fd -t f";
        preview = {
          command = "bat -n --color=always '{}'";
          env.BAT_THEME = "Catppuccin Mocha";
        };
        ui.preview_panel = {
          size = 70;
          scrollbar = true;
        };
        keybindings = {
          shortcut = "f1";
          f12 = "actions:edit";
          f11 = [
            "actions:rm"
            "reload_source"
          ];
        };
        actions = {
          edit = {
            description = "Opens the selected entries with the default editor (falls back to vim)";
            command = "\${EDITOR:-vim} {}";
            mode = "execute";
          };
          rm = {
            description = "Removes the selected entries";
            command = "rm {}";
          };
        };
      };

      findgrep = {
        metadata = {
          name = "findgrep";
          description = "Search both file names and contents";
          requirements = [
            "rg"
            "bat"
            "fd"
          ];
        };
        source.command = ''
          # Combine file paths and content lines for unified searching
          # First list all file paths
          fd -t f 2>/dev/null
          # Then add content lines with file:line:content format
          rg --no-heading --with-filename --line-number --max-columns=150 "" 2>/dev/null | head -1000
        '';
        preview = {
          command = ''
            set input '{}'
            # Check if input contains line number (file:line:content format)
            if string match -q "*:*:*" "$input"
              # It's a content match - extract file and line
              set parts (string split ":" "$input")
              set file $parts[1]
              set line_num $parts[2]
              if test -f "$file"
                bat -n --color=always --highlight-line "$line_num" "$file"
              else
                echo "File not found: $file"
              end
            else
              # It's just a file path
              if test -f "$input"
                bat -n --color=always "$input"
              else
                echo "File not found: $input"
              end
            end
          '';
          env.BAT_THEME = "Catppuccin Mocha";
        };
        ui.preview_panel = {
          size = 70;
          scrollbar = true;
        };
        keybindings = {
          shortcut = "f2";
          enter = "actions:edit";
          f12 = "actions:edit";
        };
        actions.edit = {
          description = "Open selected file";
          command = ''
            set input '{}'
            # Check if input contains line number
            if string match -q "*:*:*" "$input"
              set parts (string split ":" "$input")
              set file $parts[1]
              set line_num $parts[2]
              ''${EDITOR:-vim} "+$line_num" "$file"
            else
              ''${EDITOR:-vim} "$input"
            end
          '';
          mode = "execute";
        };
      };

      grep = {
        metadata = {
          name = "grep";
          description = "Live grep - search file contents with ripgrep";
          requirements = [
            "rg"
            "bat"
            "fzf"
          ];
        };
        source = {
          command = ''
            echo "Enter search term:" >&2
            read -P "" query
            if test -n "$query"
              rg --line-number --no-heading --color=never "$query" 2>/dev/null | \
              awk -F: '{printf "%s:%s: %s\n", $1, $2, substr($0, index($0,$3))}'
            else
              echo "No search term provided"
            end
          '';
          interactive = true;
        };
        preview = {
          command = ''
            set file (echo '{}' | cut -d: -f1)
            set line (echo '{}' | cut -d: -f2)
            if test -f "$file"
              bat -n --color=always --highlight-line "$line" "$file" 2>/dev/null
            else
              echo "File not found"
            end
          '';
          env.BAT_THEME = "Catppuccin Mocha";
        };
        ui.preview_panel = {
          size = 70;
          scrollbar = true;
        };
        keybindings = {
          shortcut = "f3";
          enter = "actions:edit";
          f12 = "actions:edit";
        };
        actions.edit = {
          description = "Open file at specific line";
          command = ''
            set file (echo '{}' | cut -d: -f1)
            set line (echo '{}' | cut -d: -f2)
            ''${EDITOR:-vim} "+$line" "$file"
          '';
          mode = "execute";
        };
      };
    };
  };
}
