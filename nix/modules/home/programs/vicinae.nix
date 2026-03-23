{
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

  services.vicinae = {
    enable = true;
    systemd = {
      enable = true; # default: false
      autoStart = true; # default: false
      environment = {
        USE_LAYER_SHELL = 1;
      };
    };
    package = perSystem.vicinae.default;
    extensions = with perSystem.vicinae-extensions; [
      # bluetooth
      nix
      # systemd
      wifi-commander
      case-converter
      pulseaudio
      process-manager
      port-killer
      niri
      # doesnt work for some reason
      # (perSystem.vicinae.mkRayCastExtension {
      #   name = "karakeep";
      #   sha256 = "sha256-DAfDI2wxZ7mkpbQ+C0Y2xEaWZ98SiEPj6S/q8xlyRC8=";
      #   rev = "3f7bf4d8f11dda61d1da77ddd4c0e67eb997d099";
      # })
      # (perSystem.vicinae.mkRayCastExtension {
      #   name = "password-generator";
      #   sha256 = "sha256-VbC6h6TuvPlnPvVGs23pefw4a4musuZI+wTUg9v+9jk=";
      #   rev = "3f7bf4d8f11dda61d1da77ddd4c0e67eb997d099";
      # })
    ];
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
          name = "vicinae-dark";
          icon_theme = "Papirus";
        };
      };
      launcher_window = {
        opacity = 0.98;
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
            Alacritty = {
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
          setup ? "",
        }:
        {
          "${scripts}/${name}.sh".source = "${
            pkgs.writeShellApplication {
              inherit name;
              runtimeInputs = runtimeInputs ++ [
                pkgs.alacritty
                pkgs.util-linux # setsid
              ];
              excludeShellChecks = [ "SC2016" ];
              text = # bash
                ''
                  # @vicinae.schemaVersion 1
                  # @vicinae.title ${title}
                  # @vicinae.mode silent
                  # @vicinae.icon ${icon}

                  ${setup}
                  setsid alacritty --class ${appId} -e bash -c ${pkgs.lib.escapeShellArg command} &>/dev/null &
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
      setup = jiraSetup;
      command = # bash
        ''jira issue list -c "${jiraConfig}" -a"$(jira me)" -s~Done'';
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
      setup = jiraSetup;
      command = # bash
        ''
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

          wl-copy $issueKey
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
          KUBECONFIG="$(find ~/.kube -maxdepth 1 -type f -name "*.yml" -o -name "*.yaml" -o -name "config" | fzf --prompt="Select kubeconfig: ")" k9s
        '';
    };
}
