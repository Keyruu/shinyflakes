{ pkgs, inputs, ... }:
{
  imports = [
    inputs.noctalia.homeModules.default
  ];

  programs.noctalia-shell = {
    enable = true;
    systemd.enable = true;
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
      mSurfaceVariant = "#1a1b26"; # slightly lighter background from waybar
      mTertiary = "#cdd6f4"; # keeping it simple with main text color
    };
    settings = {
      bar = {
        density = "default";
        position = "top";
        backgroundOpacity = 0;
        showCapsule = true;
        floating = true;
        widgets = {
          left = [
            {
              id = "SidePanelToggle";
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
          ];
        };
      };
      ui = {
        fontDefault = "JetBrainsMono Nerd Font";
        fontFixed = "JetBrainsMono Nerd Font";
      };
      # colorSchemes.predefinedScheme = "Noctalia (default)";
      general = {
        radiusRatio = 0.2;
      };
      location = {
        name = "Munich, Germany";
        firstDayOfWeek = 0;
      };
      wallpaper.enabled = false;
      dock.enabled = false;
    };
  };
}
