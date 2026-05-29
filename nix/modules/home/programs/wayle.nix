{ config, ... }:
{
  services.wayle = {
    enable = true;

    settings = {
      styling = {
        theme-provider = "wayle";
        palette =
          let
            t = config.user.theme;
          in
          {
            bg = t.background;
            inherit (t) surface elevated;
            fg = t.foreground;
            fg-muted = t.muted;
            primary = t.accent;
            inherit (t.colors)
              red
              yellow
              green
              blue
              ;
          };
      };

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
              "custom-khal"
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
        bluetooth.label-show = false;
        idle-inhibit.label-show = false;
        microphone.label-show = false;
        network.label-show = false;
        volume.label-show = false;

        custom = [
          {
            id = "khal";
            command = "wayle-event";
            interval-ms = 60000;
            icon-name = "tb-calendar-time-symbolic";
            hide-if-empty = true;
          }
        ];
      };
    };
  };
}
