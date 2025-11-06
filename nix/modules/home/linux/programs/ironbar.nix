{ inputs, pkgs, ... }:
let
  wifi-status = pkgs.writeShellScriptBin "wifi-status" ''
    wifi_state=$(${pkgs.networkmanager}/bin/nmcli -t -f TYPE,STATE device | grep '^wifi:' | cut -d: -f2)

    if [[ "$wifi_state" == "connected" ]]; then
      echo " "
    else
      echo "󰖪 "
    fi
  '';
in
{
  imports = [
    inputs.ironbar.homeManagerModules.default
  ];

  home.packages = with pkgs; [
    ironbar
    upower
    wifi-status
  ];

  programs.ironbar = {
    enable = false;
    systemd = true;
    package = pkgs.ironbar;

    config = {
      position = "top";
      height = 26;
      start = [
        {
          type = "workspaces";
          name_map = {
            "browse" = "";
            "ide" = "";
            "term" = "";
            "media" = "";
            "social" = "";
          };
          all_monitors = false;
          sort = "added";
        }
        {
          type = "script";
          name = "niri-windows";
          class = "niri-windows";
          cmd = "niri-workstyle";
          mode = "watch";
        }
        {
          type = "focused";
          show_icon = true;
          show_title = true;
          icon_size = 28;
          truncate = {
            mode = "middle";
            max_length = 50;
          };
        }
      ];
      center = [
        {
          type = "music";
          player_type = "mpris";
          format = "{artist} - {title}";
          truncate = {
            mode = "end";
            max_length = 50;
          };
        }
      ];
      end = [
        {
          type = "tray";
          icon_size = 16;
        }
        {
          type = "custom";
          class = "meeting";
          bar = [
            {
              type = "button";
              name = "meeting-btn";
              label = "{{60000:next-event}}";
              on_click = "popup:toggle";
            }
          ];
          popup = [
            {
              type = "box";
              orientation = "vertical";
              widgets = [
                {
                  type = "label";
                  name = "calendar-header";
                  label = "📅 Upcoming Events";
                }
                {
                  type = "label";
                  name = "calendar-events";
                  label = "{{60000:next-events}}";
                }
              ];
            }
          ];
        }
        {
          type = "bluetooth";
          format = {
            not_found = "󰂲";
            disabled = "󰂲";
            enabled = "";
            connected = " {device_alias}";
            connected_battery = " {device_alias} {device_battery_percent}%";
          };
          truncate = {
            mode = "end";
            max_length = 10;
          };
        }
        {
          type = "script";
          name = "wifi-status";
          cmd = "wifi-status";
          mode = "poll";
          interval = 5000;
        }
        {
          type = "sys_info";
          format = [
            " {cpu_percent}%"
            " {memory_percent}%"
          ];
          interval = {
            cpu = 1;
          };
        }
        {
          type = "battery";
          format = "{percentage}%";
        }
        {
          type = "volume";
          format = "{icon} {percentage}%";
          max_volume = 100;
        }
        {
          type = "clock";
          format = "󰃰 %d.%m. %H:%M";
        }
        {
          type = "script";
          name = "caffeine";
          cmd = "caffeine-status";
          mode = "poll";
          interval = 5000;
        }
        {
          type = "notifications";
          show_count = true;
        }
      ];
    };

    style = # css
      ''
        @define-color color_bg rgba(12, 14, 15, 0.9);
        @define-color color_border rgba(255, 255, 255, 0.3);
        @define-color color_text #cdd6f4;
        @define-color color_cyan #89dceb;
        @define-color color_teal #94e2d5;
        @define-color color_green #a6e3a1;
        @define-color color_yellow #f9e2af;
        @define-color color_blue #89b4fa;
        @define-color color_purple #cba6f7;
        @define-color color_peach #fab387;
        @define-color color_light_blue #c0caf5;
        @define-color color_red #f38ba8;
        @define-color color_active #4079d6;
        @define-color color_hover #11111b;

        * {
            font-family: "JetBrainsMono Nerd Font", sans-serif;
            font-size: 14px;
            border: none;
            box-shadow: none;
        }

        window#bar {
            background: transparent;
            color: @color_text;
        }

        popover, popover contents {
            border-radius: 12px;
            padding: 0;
            background-color: #1a1b26;
            border: 2px solid #11111b;
        }

        box, button, label, calendar {
            background-color: transparent;
        }

        .background {
          background: transparent;
        }

        bar .background {
          background: #1a1b26;
        }

        popover contents {
            background: #1a1b26;
        }

        /* Common widget styling */
        .workspaces,
        .focused,
        .tray,
        .meeting,
        .bluetooth,
        .network-manager,
        .sysinfo,
        .battery,
        .volume,
        .clock,
        .script,
        .notifications > .button,
        .custom {
            background-color: @color_bg;
            border: 1px solid @color_border;
            border-radius: 5px;
            padding-left: 7px;
            padding-right: 7px;
            margin: 2px;
        }

        /* Module spacing */
        #start > * + *, #center > * + *, #end > * + * {
            margin-left: 2px;
        }

        /* Workspaces */
        .workspaces {
            padding: 0;
        }

        .workspaces .item {
            color: @color_text;
            padding: 0 2px;
            min-width: 25px;
            transition: all 0.2s ease;
        }

        .workspaces .item.visible {
            box-shadow: none;
        }

        .workspaces .item.focused {
            color: @color_active;
            background-color: #111;
            box-shadow: none;
            border: none;
            padding: 0;
        }

        .workspaces .item:hover {
            background-color: @color_hover;
        }

        .workspaces .item.urgent {
            background-color: @color_red;
        }

        /* Focused window */
        .focused {
            color: @color_text;
        }

        /* Music */
        .music {
            background-color: @color_bg;
            border: 1px solid @color_border;
            border-radius: 5px;
            margin: 2px;
            color: @color_light_blue;
            padding: 0;
            padding-left: 0px;
            padding-right: 10px;
        }

        /* System info (CPU + Memory combined) */
        .sysinfo {
            color: @color_cyan;
        }

        /* Battery */
        .battery {
            color: @color_green;
        }

        /* Network */
        .network-manager {
            color: @color_yellow;
        }

        /* Bluetooth */
        .bluetooth {
            color: @color_blue;
        }

        /* Volume */
        .volume {
            color: @color_blue;
        }

        /* Clock */
        .clock {
            color: @color_peach;
        }

        /* Caffeine */
        .custom#caffeine {
            color: @color_yellow;
        }

        /* Meeting */
        .meeting {
            color: @color_text;
        }

        /* Niri windows */
        .script#niri-windows {
            color: @color_light_blue;
            margin-left: 2px;
            margin-right: 4px;
            padding-right: 10px;
        }

        /* WiFi status */
        .script#wifi-status {
            color: @color_yellow;
            padding-right: 10px;
        }

        /* Hover effects */
        .sysinfo:hover,
        .volume:hover,
        .network_manager:hover,
        .bluetooth:hover,
        .custom#caffeine:hover,
        .notifications:hover,
        .meeting:hover,
        .custom#niri-windows:hover,
        .script#wifi-status:hover {
            background-color: @color_hover;
        }

        button:hover, button:active {
            background-color: @color_hover;
        }

        scale.horizontal highlight {
            background: linear-gradient(90deg, @color_blue 35%, @color_purple 100%);
        }

        scale.vertical highlight {
            background: linear-gradient(0, @color_blue 35%, @color_purple 100%);
        }

        slider {
            border-radius: 100%;
        }

        dropdown popover row:hover, dropdown popover row:focus, dropdown popover row:selected {
            background-color: @color_hover;
        }

        radio {
            margin-right: 0.5em;
        }

        .popup {
            padding: 1em;
        }

        /* --- popup: clock --- */

        .popup-clock .calendar-clock {
            font-size: 2.2em;
            margin-bottom: 0.25em;
        }

        .popup-clock .calendar .today {
            background-color: @color_active;
            border-radius: 0.25em;
        }

        .popup-clipboard .item {
            padding: 0.25em;
        }

        .popup-clipboard .item + .item {
            border-top: 1px solid @color_border;
        }

        /* --- popup: menu --- */

        .menu label {
            padding: 0 0.5em;
        }

        .popup-menu .sub-menu {
            border-left: 1px solid @color_border;
            padding-left: 0.5em;
        }

        .popup-menu .category, .popup-menu .application {
            padding: 0.25em;
        }

        .popup-menu .category.open {
            background-color: @color_hover;
        }

        /* --- popup: music --- */

        .popup-music .album-art {
            margin-right: 1em;
            border-radius: 5px;
        }

        .popup-music .icon-box {
            margin-right: 0.5em;
        }

        .popup-music .title .icon, .popup-music .title .label {
            font-size: 1.5em;
        }

        .popup-music .artist .label, .popup-music .album .label {
            margin-left: 6px;
        }

        .popup-music .volume .icon {
            margin-right: 3px;
        }

        /* --- notifications --- */
        .notifications > .button {
            color: @color_blue;
            padding-right: 10px;
        }

        .notifications .count {
            font-size: 0.8em;
            padding: 0.5em;
        }

        /* --- sysinfo --- */

        .sysinfo > .item + .item {
            margin-left: 0.5em;
        }

        /* --- tray --- */

        .tray popover contents {
            padding: 1em;
        }

        /* --- popup: volume --- */

        .popup-volume .device-box {
            border-right: 1px solid @color_border;
        }

        /* --- popup: power menu --- */

        .popup-power-menu #header {
            font-size: 1.5em;
            margin-bottom: 0.6em;
        }

        .popup-power-menu .power-btn {
            border: 1px solid @color_border;
            border-radius: 10px;
            padding: 0 1.2em;
        }

        .popup-power-menu .power-btn label {
            font-size: 2.6em;
        }

        .popup-power-menu #buttons > * + * {
            margin-left: 1.3em;
        }
      '';
  };
}
