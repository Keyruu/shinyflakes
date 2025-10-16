{
  lib,
  pkgs,
  ...
}:
{
  programs.waybar = {
    enable = true;
    systemd.enable = true;

    settings = {
      mainBar = {
        layer = "top";
        position = "top";
        mod = "dock";
        exclusive = true;
        passthrough = false;
        gtk-layer-shell = true;
        modules-left = [
          "sway/workspaces"
          "sway/window"
        ];
        modules-center = [ "mpris" ];
        modules-right = [
          "tray"
          "sway/mode"
          "bluetooth"
          "network"
          "cpu"
          "memory"
          "battery"
          "pulseaudio"
          "pulseaudio#microphone"
          "clock"
          "custom/caffeine"
          "custom/swaync"
        ];

        "sway/window" = {
          icon = true;
        };

        "sway/workspaces" = {
          disable-scroll = true;
          format = "{icon}";
          format-icons = {
            "1" = "1";
            "2" = "2";
            "3" = "3";
            "4" = "4";
            "5" = "5";
            "6" = "6";
            "7" = "7";
            "8" = "8";
            "9" = "9";
            "10" = "10";
          };
          all-outputs = true;
          on-click = "activate";
        };

        tray = {
          spacing = 10;
        };

        "sway/mode" = {
          format = "󰌌 {}";
          max-length = 50;
        };

        cpu = {
          interval = 1;
          format = "  {}%";
          on-click = "foot btop";
        };

        memory = {
          interval = 1;
          format = "  {}%";
          on-click = "foot btop";
        };

        clock = {
          format = "󰃰  {:%a; %b %e %H:%M }";
          tooltip-format = "<big>{:%Y %B}</big>\n<tt><small>{calendar}</small></tt>";
        };

        battery = {
          states = {
            good = 95;
            warning = 30;
            critical = 20;
          };
          format = "{icon}  {capacity}%";
          format-icons = [
            ""
            ""
            ""
            ""
            ""
          ];
          format-charging = " {capacity}%";
          format-plugged = " {capacity}%";
          format-alt = "{time} {icon} ";
        };

        pulseaudio = {
          format = "{icon} {volume}%";
          tooltip = false;
          format-muted = " ";
          on-click = "${lib.getExe pkgs.pamixer} -t";
          on-right-click = "pavucontrol";
          on-scroll-up = "${lib.getExe pkgs.pamixer} -i 5";
          on-scroll-down = "${lib.getExe pkgs.pamixer} -d 5";
          scroll-step = 5;
          format-icons = {
            headphone = " ";
            hands-free = " ";
            headset = " ";
            phone = " ";
            portable = " ";
            car = " ";
            default = [
              " "
              " "
              " "
            ];
          };
        };

        "pulseaudio#microphone" = {
          format = "{format_source}";
          format-source = "󰍬 {volume}%";
          format-source-muted = "󰍭 ";
          on-click = "${lib.getExe pkgs.pamixer} --default-source -t";
          on-scroll-up = "${lib.getExe pkgs.pamixer} --default-source -i 5";
          on-scroll-down = "${lib.getExe pkgs.pamixer} --default-source -d 5";
          scroll-step = 5;
        };

        network = {
          format-wifi = " ";
          format-ethernet = "{ipaddr}/{cidr}";
          tooltip-format = "{essid} - {ifname} via {gwaddr}";
          format-linked = "{ifname} (No IP)";
          format-disconnected = "󰖪 ";
          # format-alt = "{ifname}:{essid} {ipaddr}/{cidr}";
          on-click = "foot impala";
        };

        bluetooth = {
          format = "";
          format-off = "󰂲";
          format-disabled = "";
          format-connected = " {num_connections}";
          tooltip-format = "{device_alias}";
          tooltip-format-connected = " {device_enumerate}";
          tooltip-format-enumerate-connected = "{device_alias}";
        };

        mpris = {
          title-len = 20;
          interval = 1;
          album-len = 0;
          max-len = 30;
          max-empty-time = 60;
          format = "{player_icon} {artist} - {title}";
          format-paused = "{status_icon} {artist} - {title}";
          player-icons = {
            default = "▶";
            mpv = "🎵";
            spotify = " ";
            spotify_player = " ";
            firefox = "";
          };
          status-icons = {
            paused = "";
          };
          ignored-players = [
            "librewolf"
            "vlc"
            "firefox"
            "brave"
          ];
        };
        "custom/caffeine" = {
          format = "{}";
          interval = 5;
          on-click = "caffeine";
          exec = "caffeine-status";
        };
        "custom/swaync" = {
          tooltip = true;
          format = "{icon}";
          format-icons = {
            notification = "󱅫";
            none = "󰂜";
            dnd-notification = "󰂠";
            dnd-none = "󰪓";
            inhibited-notification = "󰂛";
            inhibited-none = "󰪑";
            dnd-inhibited-notification = "󰂛";
            dnd-inhibited-none = "󰪑";
          };
          return-type = "json";
          exec-if = "which swaync-client";
          exec = "swaync-client -swb";
          on-click = "swaync-client -t -sw";
          on-click-right = "swaync-client -d -sw";
          escape = true;
        };
      };
    };

    style = # css
      ''
        /* Global styles */
        * {
          border: none;
          font-family: "JetBrainsMono Nerd Font";
          font-size: 14px;
          min-height: 0;
        }

        window#waybar {
          background: none;
          color: #cdd6f4;
        }

        tooltip {
          background: #1a1b26;
          border: 2px solid #11111b;
          color: #cdd6f4;
        }

        /* Common module styling */
        #workspaces,
        #window,
        #mode,
        #tray,
        #bluetooth,
        #network,
        #cpu,
        #memory,
        #battery,
        #pulseaudio,
        #pulseaudio.microphone,
        #clock,
        #mpris,
        #custom-caffeine,
        #custom-swaync,
        #custom-dunst {
          background: #0c0e0f;
          padding: 0 7px;
          margin: 0;
        }

        /* Workspaces */
        #workspaces {
          padding: 0 5px;
        }

        #workspaces button {
          color: #cdd6f4;
          padding: 5px;
          padding-right: 10px;
          min-width: 20px;
          transition: all 0.2s ease;
        }

        #workspaces button.active,
        #workspaces button.focused {
          color: #89b4fa;
          background: #111;
        }

        #workspaces button:hover {
          background: #11111b;
          color: #c0caf5;
        }

        /* Window title */
        #window {
          color: #cdd6f4;
          margin-right: 10px;
        }

        /* Mode indicator */
        #mode {
          color: #cdd6f4;
          padding: 0 5px;
        }

        /* System monitoring */
        #cpu {
          color: #89dceb;
        }

        #memory {
          color: #94e2d5;
        }

        /* Battery */
        #battery {
          color: #a6e3a1;
        }

        #battery.warning {
          color: #f9e2af;
        }

        #battery.critical {
          color: #f38ba8;
        }

        #battery.charging,
        #battery.plugged {
          color: #a6e3a1;
        }

        /* Network */
        #network {
          color: #f9e2af;
        }

        #network.disconnected {
          color: #f38ba8;
        }

        /* Bluetooth */
        #bluetooth {
          color: #89b4fa;
        }

        #bluetooth.off {
          color: #6c7086;
        }

        /* Audio */
        #pulseaudio {
          color: #89b4fa;
        }

        #pulseaudio.muted {
          color: #6c7086;
        }

        #pulseaudio.microphone {
          color: #cba6f7;
        }

        /* Clock */
        #clock {
          color: #fab387;
          padding-right: 0;
        }

        /* Media player */
        #mpris {
          color: #c0caf5;
        }

        #mpris.paused {
          color: #c0caf5;
          border-bottom: 2px solid #f9e2af;
        }

        /* Caffeine */
        #custom-caffeine {
          color: #f9e2af;
        }

        /* SwayNC notification */
        #custom-swaync {
          color: #89b4fa;
          padding-right: 10px;
        }

        /* Dunst notification */
        #custom-dunst {
          color: #ff746c;
          padding-right: 10px;
        }

        /* Hover effects for interactive modules */
        #cpu:hover,
        #memory:hover,
        #pulseaudio:hover,
        #pulseaudio.microphone:hover,
        #network:hover,
        #bluetooth:hover,
        #custom-caffeine:hover,
        #custom-swaync:hover,
        #custom-dunst:hover {
          background: #11111b;
        }
      '';
  };
}
