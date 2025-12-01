{ pkgs, ... }:
let
  noctalia-swaync = pkgs.writeShellScriptBin "noctalia-swaync" ''
    count=$(${pkgs.swaynotificationcenter}/bin/swaync-client -c)
    dnd=$(${pkgs.swaynotificationcenter}/bin/swaync-client -D)

    if [ "$dnd" = "true" ]; then
      icon="bell-off"
      text=""
    elif [ "$count" -eq 0 ]; then
      icon="bell"
      text=""
    else
      icon="bell"
      text="$count"
    fi

    # Output JSON for noctalia
    echo "{\"icon\": \"$icon\", \"text\": \"$text\"}"
  '';
in
{
  home.packages = [
    noctalia-swaync
  ];

  services.swaync = {
    enable = false;

    settings = {
      positionX = "right";
      positionY = "top";
      layer = "overlay";
      control-center-layer = "top";
      layer-shell = false;
      cssPriority = "user";
      control-center-margin-top = 0;
      control-center-margin-bottom = 0;
      control-center-margin-right = 0;
      control-center-margin-left = 0;
      notification-2fa-action = true;
      notification-inline-replies = true;
      notification-icon-size = 64;
      notification-body-image-height = 100;
      notification-body-image-width = 200;
      timeout = 10;
      timeout-low = 5;
      timeout-critical = 15;
      fit-to-screen = true;
      control-center-width = 500;
      control-center-height = 600;
      notification-window-width = 500;
      keyboard-shortcuts = true;
      image-visibility = "when-available";
      transition-time = 200;
      hide-on-clear = false;
      hide-on-action = true;
      script-fail-notify = true;

      notification-visibility = {
        spotify-app = {
          state = "transient";
          app-name = "Spotify";
        };
        spotify-player = {
          state = "transient";
          app-name = "spotify_player";
        };
        swayidle = {
          state = "transient";
          summary = "swayidle";
        };
        caffeine = {
          state = "transient";
          summary = "Caffeine.*";
        };
      };

      widgets = [
        "label"
        "mpris"
        "title"
        "dnd"
        "notifications"
      ];

      widget-config = {
        title = {
          text = "Notifications";
          clear-all-button = true;
          button-text = "Clear All";
        };
        dnd = {
          text = "Do Not Disturb";
        };
        label = {
          max-lines = 5;
          text = "Notification Center";
        };
        mpris = {
          image-size = 96;
          image-radius = 12;
        };
      };
    };

    style = # css
      ''
        .image {
          margin-right: 1rem;
        }
      '';
  };

  xdg.desktopEntries.swaync = {
    name = "Notification Center";
    exec = "swaync-client -t -sw";
    terminal = false;
    type = "Application";
    categories = [ "Utility" ];
    icon = "notifications";
  };

  xdg.desktopEntries.clear-swaync = {
    name = "Clear Notifications";
    exec = "swaync-client -d -sw";
    terminal = false;
    type = "Application";
    categories = [ "Utility" ];
    icon = "notification-disabled";
  };
}
