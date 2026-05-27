{ ... }:
{
  services.wayle = {
    enable = true;

    settings = {
      bar = {
        bg = "transparent";
        button-variant = "basic";
        scale = 0.85;
        layout = [
          {
            monitor = "*";
            show = true;
            left = [
              "dashboard"
              "niri-workspaces"
              "window-title"
            ];
            center = [ "media" ];
            right = [
              "systray"
              "bluetooth"
              "network"
              "battery"
              "microphone"
              "volume"
              "idle-inhibit"
              "clock"
              "notifications"
            ];
          }
        ];
      };
      modules = {
        clock = {
          format = "%d.%m - %H:%M";
        };
      };
    };
  };
}
