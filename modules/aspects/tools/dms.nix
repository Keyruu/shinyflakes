{ inputs, ... }:
{
  den.aspects.tools.dms = {
    homeManager =
      { config, user, ... }:
      let
        t = user.theme;

        # Shared DankBar defaults for both `default` and `laptop` bars. Per-bar
        # entries override id / name / screenPreferences / fontScale / iconScale
        # and their widget lists.
        commonBar = {
          enabled = true;
          position = 0;
          showOnLastDisplay = false;
          autoHide = false;
          bottomGap = 0;
          transparency = 0.7;
          widgetTransparency = 1;
          noBackground = false;
          spacing = 5;
          innerPadding = 5;
          popupGapsAuto = true;
          popupGapsManual = 4;
          scrollEnabled = true;
          scrollXBehavior = "column";
          scrollYBehavior = "workspace";
          maximizeDetection = true;
          squareCorners = false;
          visible = true;
          shadowIntensity = 0;
          attachToScreenEdge = false;
          gothCornersEnabled = false;
          borderEnabled = false;
          hoverPopouts = true;
        };

        # Both bars share identical widget layouts — defined once.
        leftWidgets = [
          { id = "workspaceSwitcher"; enabled = true; }
          {
            id = "runningApps";
            enabled = true;
            runningAppsCompactMode = true;
            runningAppsCurrentWorkspace = true;
            runningAppsGroupByApp = true;
            runningAppsCurrentMonitor = false;
          }
          {
            id = "focusedWindow";
            enabled = true;
            focusedWindowSize = 1;
            focusedWindowCompactMode = false;
          }
        ];

        centerWidgets = [
          { id = "music"; enabled = true; mediaSize = 0; }
        ];

        rightWidgets = [
          { id = "systemTray"; enabled = true; }
          { id = "khalNextEvent"; enabled = true; }
          {
            id = "cpuUsage";
            enabled = true;
            minimumWidth = true;
            showLabel = false;
          }
          {
            id = "memUsage";
            enabled = true;
            minimumWidth = true;
            showLabel = false;
            showSwap = false;
          }
          {
            id = "controlCenterButton";
            enabled = true;
            showNetworkIcon = true;
            showBluetoothIcon = true;
            showAudioIcon = true;
            showAudioPercent = true;
            showVpnIcon = true;
            showBrightnessIcon = false;
            showBrightnessPercent = false;
            showMicIcon = true;
            showMicPercent = true;
            showBatteryIcon = true;
            showPrinterIcon = false;
            showScreenSharingIcon = true;
            showIdleInhibitorIcon = true;
            showDoNotDisturbIcon = false;
            controlCenterGroupOrder = [
              "network"
              "vpn"
              "bluetooth"
              "audio"
              "microphone"
              "brightness"
              "battery"
              "printer"
              "screenSharing"
              "idleInhibitor"
              "doNotDisturb"
            ];
          }
          { id = "clock"; enabled = true; clockDateOrder = "dateFirst"; }
        ];
      in
      {
        imports = [
          inputs.dms.homeModules.dank-material-shell
        ];

        programs.dank-material-shell = {
          enable = true;

          systemd = {
            enable = true;
            restartIfChanged = true;
          };

          enableSystemMonitoring = true;
          enableClipboardPaste = true;
          enableCalendarEvents = true;

          plugins = {
            khalNextEvent = {
              enable = true;
              src = ./dms-plugins/khal-next-event;
            };
          };

          settings = {
            currentThemeName = "custom";
            customThemeFile = "${config.home.homeDirectory}/.config/DankMaterialShell/theme.json";
            clockFormat = "24h";
            barElevationEnabled = false;
            blurEnabled = true;
            controlCenterWidgets = [
              { id = "volumeSlider"; enabled = true; width = 50; }
              { id = "inputVolumeSlider"; enabled = true; width = 50; }
              { id = "brightnessSlider"; enabled = true; width = 50; }
              { id = "wifi"; enabled = true; width = 50; }
              { id = "bluetooth"; enabled = true; width = 50; }
              { id = "audioOutput"; enabled = true; width = 50; }
              { id = "audioInput"; enabled = true; width = 50; }
              { id = "battery"; enabled = true; width = 50; }
              { id = "nightMode"; enabled = true; width = 50; }
              { id = "idleInhibitor"; enabled = true; width = 50; }
              { id = "builtin_vpn"; enabled = true; width = 50; }
              { id = "colorPicker"; enabled = true; width = 50; }
              {
                id = "diskUsage";
                enabled = true;
                width = 50;
                instanceId = "mttwzfnrtkf31t8zlbr1jaruf4grv";
                mountPath = "/";
                showMountPath = true;
              }
              { id = "builtin_cups"; enabled = true; width = 50; }
            ];
            showWorkspaceName = true;
            workspaceFollowFocus = true;
            workspaceActiveAppHighlightEnabled = true;
            clockDateFormat = "ddd dd.MM.";
            acMonitorTimeout = 310;
            acLockTimeout = 300;
            acSuspendTimeout = 900;
            acPostLockMonitorTimeout = 60;
            batteryMonitorTimeout = 310;
            batteryLockTimeout = 300;
            batterySuspendTimeout = 900;
            lockBeforeSuspend = true;

            builtInPluginSettings = {
              dms_settings_search = { trigger = "?"; };
              dms_clipboard_search = { trigger = "cb"; };
              dms_power = { trigger = "pw"; };
              dms_qr_generator = { trigger = "qrg"; };
            };

            configVersion = 18;

            barConfigs = [
              (commonBar // {
                id = "default";
                name = "Main Bar";
                screenPreferences = [
                  "HDMI-A-1"
                  "HDMI-A-2"
                  "DP-1"
                  "DP-2"
                  "DP-3"
                  "DVI-I-1"
                ];
                fontScale = 0.9;
                iconScale = 0.8;
                maximizeWidgetIcons = false;
                maximizeWidgetText = false;
                removeWidgetPadding = false;
                widgetPadding = 9;
                barInsetPadding = 24;
                island = false;

                inherit leftWidgets centerWidgets rightWidgets;
              })
              (commonBar // {
                id = "laptop";
                name = "Laptop Bar";
                screenPreferences = [ "eDP-1" ];
                fontScale = 0.85;
                iconScale = 0.85;
                island = false;

                inherit leftWidgets centerWidgets rightWidgets;
              })
            ];
          };

          # wallpaperPath lives in session.json (SessionSpec), not settings.json
          session = {
            wallpaperPath = ../../../assets/dark-bg.jpg;
            wallpaperFillMode = "Fill";
          };
        };

        xdg.desktopEntries = {
          caffeine = {
            name = "Caffeine";
            exec = "dms ipc call inhibit toggle";
            categories = [ "Utility" ];
            icon = "caffeine";
          };

          notification-center = {
            name = "Notification Center";
            exec = "dms ipc call notifications toggle";
            categories = [ "Utility" ];
            icon = "notifications";
          };

          clear-notification = {
            name = "Clear Notifications";
            exec = "dms ipc call notifications clearAll";
            categories = [ "Utility" ];
            icon = "notification-disabled";
          };

          do-not-disturb = {
            name = "Toggle DND";
            exec = "dms ipc call notifications toggleDoNotDisturb";
            categories = [ "Utility" ];
            icon = "notification-disabled";
          };

          dms-calendar = {
            name = "DMS Calendar";
            exec = "dms ipc call dash toggle overview";
            categories = [ "Office" ];
            icon = "calendar";
          };
        };

        xdg.configFile."DankMaterialShell/theme.json".text = builtins.toJSON {
          dark = {
            name = "Noctalia Dark";
            primary = t.accent;
            primaryText = t.onAccent;
            primaryContainer = "#2a5499";
            secondary = t.colors.blue;
            surface = t.background;
            surfaceText = t.foreground;
            surfaceVariant = t.surface;
            surfaceVariantText = t.muted;
            surfaceTint = t.accent;
            background = t.background;
            backgroundText = t.foreground;
            outline = t.border;
            surfaceContainer = "#161616";
            surfaceContainerHigh = t.surface;
            surfaceContainerHighest = t.elevated;
            error = t.colors.red;
            warning = t.colors.yellow;
            info = t.colors.blue;
            matugen_type = "scheme-tonal-spot";
          };
        };
      };
  };
}