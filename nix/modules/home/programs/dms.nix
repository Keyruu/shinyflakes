{
  inputs,
  config,
  pkgs,
  ...
}:
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
        src = ./dms/khal-next-event;
      };
    };

    settings = {
      currentThemeName = "custom";
      customThemeFile = "${config.home.homeDirectory}/.config/DankMaterialShell/theme.json";
      blurEnabled = true;
      use24HourClock = true;
      clockDateFormat = "ddd dd.MM.";
      showOccupiedWorkspacesOnly = true;
      runningAppsCurrentWorkspace = true;
      scrollTitleEnabled = true;
      soundsEnabled = true;
      soundNewNotification = true;

      # idle: lock at 5min, screen off at 5min+10s, suspend at 15min
      acLockTimeout = 300;
      acMonitorTimeout = 310;
      acSuspendTimeout = 900;
      batteryLockTimeout = 300;
      batteryMonitorTimeout = 310;
      batterySuspendTimeout = 900;
      lockBeforeSuspend = true;
      fadeToLockEnabled = true;
      fadeToLockGracePeriod = 5;
      fadeToDpmsEnabled = true;
      fadeToDpmsGracePeriod = 5;

      barConfigs =
        let
          commonBar = {
            enabled = true;
            position = 0;
            showOnLastDisplay = true;
            transparency = 0.7;
            widgetTransparency = 1.0;
            noBackground = false;
            spacing = 5;
            innerPadding = 5;
            bottomGap = 0;

            leftWidgets = [
              {
                id = "launcherButton";
                enabled = true;
              }
              {
                id = "workspaceSwitcher";
                enabled = true;
              }
              {
                id = "runningApps";
                enabled = true;
                runningAppsCompactMode = true;
                runningAppsCurrentWorkspace = true;
              }
              {
                id = "focusedWindow";
                enabled = true;
              }
            ];

            centerWidgets = [
              {
                id = "music";
                enabled = true;
              }
            ];

            rightWidgets = [
              {
                id = "systemTray";
                enabled = true;
              }
              {
                id = "khalNextEvent";
                enabled = true;
              }
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
                id = "battery";
                enabled = true;
              }

              {
                id = "controlCenterButton";
                enabled = true;
                showNetworkIcon = true;
                showBluetoothIcon = true;
                showAudioIcon = true;
                showAudioPercent = false;
                showMicIcon = true;
                showMicPercent = false;
                showBrightnessIcon = false;
              }
              {
                id = "clock";
                enabled = true;
              }
              {
                id = "idleInhibitor";
                enabled = true;
              }
              {
                id = "notificationButton";
                enabled = true;
              }
            ];

            scrollEnabled = true;
            scrollXBehavior = "column";
            scrollYBehavior = "workspace";
            maximizeDetection = true;
            squareCorners = false;
            visible = true;
            autoHide = false;
            popupGapsAuto = true;
            popupGapsManual = 4;
          };
        in
        [
          (
            commonBar
            // {
              id = "default";
              name = "Main Bar";
              screenPreferences = [ "all" ];
              fontScale = 1.0;
              iconScale = 1.0;
            }
          )
          (
            commonBar
            // {
              id = "laptop";
              name = "Laptop Bar";
              screenPreferences = [ "eDP-1" ];
              fontScale = 0.85;
              iconScale = 0.85;
            }
          )
        ];
    };
  };

  xdg.configFile."DankMaterialShell/theme.json".source = ./dms/theme.json;
}
