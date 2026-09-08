{ inputs, ... }:
{
  den.aspects.tools.dms = {
    homeManager =
      { config, pkgs, user, ... }:
      let
        t = user.theme;
      in
      {
        imports = [
          inputs.dms.homeModules.dank-material-shell
        ];

        # qt5ct/qt6ct read ~/.config/qt{5,6}ct/colors.conf (dms writes it via
        # matugen) only when QT_QPA_PLATFORMTHEME points at them. Without
        # this env var, Qt apps use their built-in defaults and ignore dms.
        home.sessionVariables.QT_QPA_PLATFORMTHEME = "qt6ct";

        home.packages = with pkgs; [
          qt6Packages.qt6ct
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
            showWorkspaceName = true;
            showWorkspaceApps = true;
            workspaceFollowFocus = true;
            workspaceActiveAppHighlightEnabled = true;
            clockDateFormat = "ddd dd.MM.";
            acMonitorTimeout = 310;
            acLockTimeout = 300;
            acSuspendTimeout = 900;
            batteryMonitorTimeout = 310;
            batteryLockTimeout = 300;
            batterySuspendTimeout = 900;
            lockBeforeSuspend = true;
            dankIslandBarId = "default";
            dankIslandHomeCompactTight = true;

            desktopClockCustomColor = {
              r = 1; g = 1; b = 1; a = 1;
              hsvHue = -1; hsvSaturation = 0; hsvValue = 1;
              hslHue = -1; hslSaturation = 0; hslLightness = 1;
              valid = true;
            };

            systemMonitorCustomColor = {
              r = 1; g = 1; b = 1; a = 1;
              hsvHue = -1; hsvSaturation = 0; hsvValue = 1;
              hslHue = -1; hslSaturation = 0; hslLightness = 1;
              valid = true;
            };

            builtInPluginSettings = {
              dms_settings_search = { trigger = "?"; };
              dms_clipboard_search = { trigger = "cb"; };
              dms_power = { trigger = "pw"; };
              dms_qr_generator = { trigger = "qrg"; };
            };

            configVersion = 17;

            barConfigs = [
              {
                id = "default";
                name = "Main Bar";
                enabled = true;
                position = 0;
                screenPreferences = [ "all" ];
                showOnLastDisplay = true;
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
                maximizeWidgetIcons = false;
                maximizeWidgetText = false;
                removeWidgetPadding = false;
                widgetPadding = 9;
                barInsetPadding = 24;
                fontScale = 0.9;
                iconScale = 0.8;

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
                  { id = "music"; enabled = true; }
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
                  { id = "battery"; enabled = true; }
                  { id = "clock"; enabled = true; }
                  { id = "idleInhibitor"; enabled = true; }
                  { id = "notificationButton"; enabled = true; }
                ];
              }
              {
                id = "laptop";
                name = "Laptop Bar";
                enabled = true;
                position = 0;
                screenPreferences = [ "eDP-1" ];
                showOnLastDisplay = true;
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
                fontScale = 0.85;
                iconScale = 0.85;

                leftWidgets = [
                  { id = "launcherButton"; enabled = true; }
                  { id = "workspaceSwitcher"; enabled = true; }
                  {
                    id = "runningApps";
                    enabled = true;
                    runningAppsCompactMode = true;
                    runningAppsCurrentWorkspace = true;
                  }
                  { id = "focusedWindow"; enabled = true; }
                ];

                centerWidgets = [
                  { id = "music"; enabled = true; }
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
                  { id = "battery"; enabled = true; }
                  {
                    id = "controlCenterButton";
                    enabled = true;
                    showAudioIcon = true;
                    showAudioPercent = false;
                    showBluetoothIcon = true;
                    showBrightnessIcon = false;
                    showMicIcon = true;
                    showMicPercent = false;
                    showNetworkIcon = true;
                  }
                  { id = "clock"; enabled = true; }
                  { id = "idleInhibitor"; enabled = true; }
                  { id = "notificationButton"; enabled = true; }
                ];
              }
            ];
          };

          # wallpaperPath lives in session.json (SessionSpec), not settings.json
          session = {
            wallpaperPath = ../../../assets/dark-bg.jpg;
            wallpaperFillMode = "Fill";
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