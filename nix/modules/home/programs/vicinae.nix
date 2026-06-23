{
  lib,
  config,
  inputs,
  perSystem,
  pkgs,
  ...
}:
{
  xdg.desktopEntries.vicinae-deeplink = {
    name = "Vicinae Deeplink Handler";
    exec = "vicinae %u";
    icon = "vicinae";
    type = "Application";
    categories = [
      "System"
      "Utility"
    ];
    genericName = "Vicinae Deeplink Handler";
    comment = "Open Vicinae Deeplinks";
    terminal = false;
    noDisplay = true;
    mimeType = [
      "x-scheme-handler/vicinae"
      "x-scheme-handler/raycast"
      "x-scheme-handler/com.raycast"
    ];
  };

  imports = [
    inputs.vicinae.homeManagerModules.default
  ];

  programs.vicinae = {
    enable = true;
    themes.shinyflakes =
      let
        t = config.user.theme;
      in
      {
        meta = {
          version = 1;
          name = "Shinyflakes";
          description = "Shared shinyflakes palette";
          variant = "dark";
          inherits = "vicinae-dark";
        };
        colors = {
          core = {
            inherit (t) background;
            inherit (t) foreground;
            secondary_background = t.surface;
            inherit (t) border;
            inherit (t) accent;
            accent_foreground = t.onAccent;
          };
          accents = {
            blue = t.colors.blue;
            green = t.colors.green;
            magenta = t.colors.magenta;
            orange = t.colors.orange;
            purple = t.colors.purple;
            red = t.colors.red;
            yellow = t.colors.yellow;
            cyan = t.colors.cyan;
          };
          main_window = {
            inherit (t) border;
            footer.background = t.surface;
          };
          settings_window.border = t.border;
          shortcut.border = t.border;
          text = {
            default = t.foreground;
            inherit (t) muted;
            danger = t.colors.red;
            success = t.colors.green;
            placeholder = t.muted;
            links = {
              default = t.accent;
              visited = t.colors.purple;
            };
            selection = {
              background = t.accent;
              foreground = t.onAccent;
            };
          };
          input = {
            inherit (t) border;
            border_focus = t.accent;
            border_error = t.colors.red;
          };
          button.primary = {
            background = t.accent;
            foreground = t.onAccent;
            hover.background = t.accent;
            hover.foreground = t.onAccent;
            focus.outline = t.accent;
          };
          list.item = {
            hover = {
              background = t.surface;
              inherit (t) foreground;
              secondary_foreground = t.muted;
            };
            selection = {
              background = t.elevated;
              inherit (t) foreground;
              secondary_background = t.surface;
              secondary_foreground = t.muted;
            };
          };
          grid.item = {
            selection.outline = t.accent;
            hover.outline = t.border;
            background = t.surface;
          };
          scrollbars = {
            background = t.border;
            secondary_background = t.surface;
          };
          tooltip = {
            background = t.surface;
            inherit (t) foreground border;
          };
          loading = {
            bar = t.accent;
            spinner = t.accent;
          };
        };
      };

    systemd = {
      enable = true;
      autoStart = true;
      environment.USE_LAYER_SHELL = 1;
    };

    package = perSystem.vicinae.default;
    extensions =
      (with perSystem.vicinae-extensions; [
        agenda
        bluetooth
        nix
        # systemd
        wifi-commander
        case-converter
        pulseaudio
        process-manager
        port-killer
        niri
      ])
      ++ (with perSystem.self; [
        raycast-karakeep
        raycast-password-generator
        raycast-quick-calendar
        raycast-gif-search
      ]);
    settings = {
      favicon_service = "twenty";
      font.normal = {
        size = 11;
        normal = config.user.font;
      };
      pop_to_root_on_close = false;
      search_files_in_root = false;
      close_on_focus_loss = true;
      theme = {
        dark = {
          name = "shinyflakes";
          icon_theme = "Papirus";
        };
      };
      launcher_window = {
        opacity = 0.90;
      };
      providers = {
        clipboard = {
          entrypoints = {
            history = {
              preferences = {
                defaultAction = "copy";
              };
            };
          };
        };
        power = {
          entrypoints = {
            power-off = {
              alias = "shutdown";
            };
          };
        };
        applications = {
          entrypoints = {
            clear-notification = {
              alias = "cn";
            };
            notification-center = {
              alias = "nc";
            };
            foot = {
              alias = "t";
            };
            slack = {
              alias = "s";
            };
            spotify = {
              alias = "m";
            };
            zen-beta = {
              alias = "b";
            };
          };
        };
        "@knoopx/vicinae-extension-nix-0" = {
          entrypoints = {
            home-manager-options = {
              alias = "nh";
            };
            options = {
              alias = "no";
            };
            packages = {
              alias = "np";
            };
          };
        };
      };
    };
  };

  home.file =
    let
      scripts = ".local/share/vicinae/scripts";
      jiraConfig = "/home/lucas/.config/.jira/.config.yml";

      mkTerminalScript =
        {
          name,
          title,
          icon ? "🚀",
          runtimeInputs ? [ ],
          command,
          appId ? "vicinae-script",
          hold ? true,
        }:
        {
          "${scripts}/${name}.sh".source = "${
            pkgs.writeShellApplication {
              inherit name;
              inherit runtimeInputs;
              excludeShellChecks = [ "SC2016" ];
              text = # bash
                ''
                  # @vicinae.schemaVersion 1
                  # @vicinae.title ${title}
                  # @vicinae.mode terminal
                  # @vicinae.terminal {"hold": ${lib.boolToString hold}, "appId": "${appId}"}
                  # @vicinae.icon ${icon}

                  ${command}
                '';
            }
          }/bin/${name}";
        };

      jiraSetup = # bash
        ''
          JIRA_API_TOKEN="$(cat ${config.sops.secrets.jiraToken.path})"
          JIRA_CONFIG_FILE="${jiraConfig}"
          export JIRA_API_TOKEN
          export JIRA_CONFIG_FILE
        '';
    in
    mkTerminalScript {
      name = "list-issues";
      title = "List Issues";
      icon = "✅";
      runtimeInputs = [ pkgs.jira-cli-go ];
      command = # bash
        ''
          ${jiraSetup}
          jira issue list -c "${jiraConfig}" -a"$(jira me)" -s~Done
        '';
    }
    // mkTerminalScript {
      name = "create-issue";
      title = "Create Issue";
      icon = "📝";
      runtimeInputs = with pkgs; [
        jira-cli-go
        fzf
        jq
        curl
        wl-clipboard
      ];
      command = # bash
        ''
          ${jiraSetup}
          if ! jira issue create; then
            echo "Issue creation was aborted or failed. Exiting."
            read -r 
            exit 1
          fi

          raw=$(jira issue list \
            --paginate 1 \
            --raw)
          issueKey=$(echo "$raw" | jq -r '.[0].key // empty')

          if [[ -z "$issueKey" ]]; then
            echo "Failed to get newest issue."
            read -r
            exit 1
          fi

          wl-copy "$issueKey"
          echo "Created and copied $issueKey"

          jira issue move "$issueKey"
          jira issue assign "$issueKey"
        '';
    }
    // mkTerminalScript {
      name = "k9s";
      title = "K9s";
      icon = "☸️";
      runtimeInputs = [
        pkgs.k9s
        pkgs.fzf
        pkgs.findutils
      ];
      command = # bash
        ''
          select-k9s
        '';
    }
    // mkTerminalScript {
      name = "mesh-tunnel";
      title = "Mesh Tunnel";
      icon = "🔒";
      appId = "vicinae-script-sm";
      hold = false;
      runtimeInputs = [ pkgs.fzf ];
      command = # bash
        ''
          mesh-tunnel
        '';
    };
}
