{
  config,
  inputs,
  pkgs,
  ...
}:
let
  # yoinked from https://github.com/iynaix/dotfiles/blob/6fbee83cd1f404245b24164e8e95a36c31b4b973/modules/gui/noctalia/default.nix#L19
  noctalia-ipc =
    with pkgs;
    writeShellApplication {
      name = "noctalia-ipc";
      runtimeInputs = [
        killall
        jq
      ];
      text = # sh
        let
          shell = "${config.programs.noctalia-shell.package}/bin/noctalia-shell";
        in
        ''
          RAW_OUTPUT=$(${shell} list --all --json 2>/dev/null)

          # invalid json, no instances running, so start noctalia-shell
          if [[ ! "$RAW_OUTPUT" == "["* ]]; then
            ${shell}
            exit
          fi

          NOCTALIA_PATH=$(${shell} list --all --json | jq -r '.[] | .config_path | sub("/share/noctalia-shell/shell.qml$"; "")')

          # using dev version, don't kill the shell
          if [[ "$NOCTALIA_PATH" == *"_dirty"* ]]; then
            "$NOCTALIA_PATH/bin/noctalia-shell" ipc call "$@"
            exit
          fi

          # Check if the running instance is from the same nix store path
          CURRENT_STORE_PATH="${config.programs.noctalia-shell.package}"
          if [[ "$NOCTALIA_PATH" != "$CURRENT_STORE_PATH" ]]; then
            echo "Noctalia updated, restarting..." >&2
            killall .quickshell-wra || true
            ${shell}
            # Wait for the new instance to be fully ready
            sleep 2
            # Retry the IPC call after restart
            ${shell} ipc call "$@"
            exit
          fi

          ${shell} ipc call "$@"
        '';
    };
in
{
  imports = [
    inputs.noctalia.homeModules.default
  ];

  home.packages = [ noctalia-ipc ];

  programs.noctalia-shell = {
    enable = true;

    plugins = {
      sources = [
        {
          enabled = true;
          name = "Official Noctalia Plugins";
          url = "https://github.com/noctalia-dev/noctalia-plugins";
        }
      ];
      states = {
        notes-scratchpad = {
          enabled = true;
          sourceUrl = "https://github.com/noctalia-dev/noctalia-plugins";
        };
      };
      version = 2;
    };

    colors = {
      mError = "#f38ba8"; # red from waybar critical state
      mOnError = "#111111";
      mOnPrimary = "#111111";
      mOnSecondary = "#111111";
      mOnSurface = "#cdd6f4"; # main text color from waybar
      mOnSurfaceVariant = "#828282"; # muted text
      mOnTertiary = "#111111";
      mOutline = "#3c3c3c"; # subtle border
      mPrimary = "#4079d6"; # blue from waybar active workspaces
      mSecondary = "#89b4fa"; # lighter blue accent from waybar
      mShadow = "#000000";
      mSurface = "#111111"; # dark background
      mSurfaceVariant = "#1E1E1E"; # slightly lighter background from waybar
      mTertiary = "#cdd6f4"; # keeping it simple with main text color
      mHover = "#89b4fa";
      mOnHover = "#111111";
    };
    settings = {
      bar = {
        density = "default";
        position = "top";
        backgroundOpacity = 0;
        showCapsule = true;
        floating = true;
        useSeparateOpacity = true;
        widgets = {
          left = [
            {
              id = "ControlCenter";
              useDistroLogo = true;
            }
            {
              hideUnoccupied = false;
              id = "Workspace";
              labelMode = "none";
            }
            {
              id = "Taskbar";
              onlySameOutput = true;
              onlyActiveWorkspaces = true;
            }
            {
              id = "ActiveWindow";
              showIcon = false;
              scrollingMode = "hover";
              maxWidth = 500;
            }
          ];
          center = [
            {
              id = "MediaMini";
              maxWidth = 500;
              showVisualizer = true;
              showAlbumArt = true;
            }
          ];
          right = [
            {
              id = "Tray";
            }
            {
              id = "CustomButton";
              icon = "calendar";
              textCommand = "noctalia-event";
              textIntervalMs = 60000;
              parseJson = true;
              maxTextLength.horizontal = 43;
            }
            {
              id = "WiFi";
            }
            {
              id = "Bluetooth";
            }
            {
              id = "SystemMonitor";
              showCpuUsage = true;
              showCpuTemp = false;
              showMemoryUsage = true;
              showMemoryAsPercent = true;
              usePrimaryColor = false;
            }
            {
              alwaysShowPercentage = false;
              id = "Battery";
              warningThreshold = 30;
            }
            {
              id = "Volume";
            }
            {
              id = "Microphone";
            }
            {
              formatHorizontal = "dd.MM. HH:mm";
              formatVertical = "HH mm";
              id = "Clock";
              useMonospacedFont = true;
              usePrimaryColor = false;
            }
            {
              id = "KeepAwake";
            }
            {
              id = "NotificationHistory";
              showUnreadBadge = true;
              hideWhenZero = true;
            }
            # {
            #   id = "CustomButton";
            #   icon = "bell";
            #   textCommand = "noctalia-swaync";
            #   textIntervalMs = 2500;
            #   parseJson = true;
            #   leftClickExec = "swaync-client -t -sw";
            #   rightClickExec = "swaync-client -C";
            # }
          ];
        };
      };
      ui = {
        fontDefault = config.user.font;
        fontFixed = config.user.font;
      };
      # colorSchemes.predefinedScheme = "Noctalia (default)";
      general = {
        radiusRatio = 1;
      };
      wallpaper = {
        enabled = true;
        directory = ../themes;
        overviewEnabled = true;
      };
      notifications = {
        enabled = true;
        sounds = {
          enabled = true;
          excludedApps = "discord,firefox,chrome,chromium,edge,Slack";
        };
      };
      location = {
        name = "Munich, Germany";
        firstDayOfWeek = 0;
      };
      idle = {
        enabled = false;
        fadeDuration = 5;
        lockTimeout = 330;
        screenOffTimeout = 300;
        suspendTimeout = 900;
      };
      dock.enabled = false;
    };
  };

  xdg.desktopEntries = {
    caffeine = {
      name = "Caffeine";
      exec = "noctalia-ipc idleInhibitor toggle";
      terminal = false;
      type = "Application";
      categories = [ "Utility" ];
      icon = "caffeine";
    };

    notification-center = {
      name = "Notification Center";
      exec = "noctalia-ipc notifications toggleHistory";
      terminal = false;
      type = "Application";
      categories = [ "Utility" ];
      icon = "notifications";
    };

    clear-notification = {
      name = "Clear Notifications";
      exec = "noctalia-ipc notifications clear";
      terminal = false;
      type = "Application";
      categories = [ "Utility" ];
      icon = "notification-disabled";
    };

    do-not-disturb = {
      name = "Toggle DND";
      exec = "noctalia-ipc notifications toggleDND";
      terminal = false;
      type = "Application";
      categories = [ "Utility" ];
      icon = "notification-disabled";
    };
  };
}
