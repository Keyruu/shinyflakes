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

    managePluginSettings = true;
    plugins = {
      khalNextEvent = {
        enable = true;
        src = ./dms/khal-next-event;
      };
    };

    session = {
      wallpaperPath = ../themes/dark-bg.jpg;
    };

    settings = {
      currentThemeName = "custom";
      customThemeFile = ./dms/theme.json;
      blurEnabled = true;
      blurWallpaperOnOverview = true;
      use24HourClock = true;
      clockDateFormat = "ddd dd.MM.";
      showOccupiedWorkspacesOnly = false;
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

      barConfigs = [
        {
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
          id = "default";
          name = "Bar";
          screenPreferences = [ "all" ];
          fontScale = 0.85;
          iconScale = 0.85;
        }
      ];
    };
  };

  xdg.configFile."DankMaterialShell/theme.json".source = ./dms/theme.json;

  xdg.desktopEntries = {
    dms-caffeine = {
      name = "Caffeine";
      exec = "dms ipc call inhibit toggle";
      terminal = false;
      type = "Application";
      categories = [ "Utility" ];
      icon = "caffeine";
    };

    dms-notification-center = {
      name = "Notification Center";
      exec = "dms ipc call notifications toggle";
      terminal = false;
      type = "Application";
      categories = [ "Utility" ];
      icon = "notifications";
    };

    dms-clear-notifications = {
      name = "Clear Notifications";
      exec = "dms ipc call notifications close";
      terminal = false;
      type = "Application";
      categories = [ "Utility" ];
      icon = "notification-disabled";
    };

    dms-notepad = {
      name = "Notepad";
      exec = "dms ipc call notepad toggle";
      terminal = false;
      type = "Application";
      categories = [ "Utility" ];
      icon = "accessories-text-editor";
    };
  };
}
