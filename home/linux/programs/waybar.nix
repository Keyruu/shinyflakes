{config, lib, pkgs, ...}: {
  stylix.targets.waybar.enable = false;

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
        modules-left = [ "hyprland/workspaces" "hyprland/window" ];
        modules-center = [ "mpris" ];
        modules-right = [ "tray" "bluetooth" "network" "cpu" "memory" "battery" "power-profiles-daemon" "pulseaudio" "pulseaudio#microphone" "clock" "custom/dunst" ];
        "hyprland/window" = {
          icon = true;
        };

        "hyprland/workspaces" = {
          disable-scroll = true;
          format = "{icon} {windows}";
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
          window-rewrite-default = "";
          window-rewrite = {
            "class<firefox|org.mozilla.firefox|librewolf|floorp|mercury-browser|[Cc]achy-browser>" = " ";
            "class<zen>" = "󰰷";
            "class<waterfox|waterfox-bin>" = "";
            "class<microsoft-edge>" = "";
            "class<Chromium|Thorium|[Cc]hrome>" = "";
            "class<brave-browser>" = "🦁";
            "class<tor browser>" = "";
            "class<firefox-developer-edition>" = "🦊";

            "class<kitty|konsole>" = "";
            "class<kitty-dropterm>" = "";
            "class<com.mitchellh.ghostty>" = "";
            "class<org.wezfurlong.wezterm>" = "";

            "class<[Tt]hunderbird|[Tt]hunderbird-esr>" = "";
            "class<eu.betterbird.Betterbird>" = "";
            "title<.*gmail.*>" = "󰊫";

            "class<[Tt]elegram-desktop|org.telegram.desktop|io.github.tdesktop_x64.TDesktop>" = "";
            "class<discord|[Ww]ebcord|Vesktop>" = "";
            "title<.*whatsapp.*>" = "";
            "title<.*zapzap.*>" = "";
            "title<.*messenger.*>" = "";
            "title<.*facebook.*>" = "";
            "title<.*reddit.*>" = "";

            "title<.*ChatGPT.*>" = "󰚩";
            "title<.*deepseek.*>" = "󰚩";
            "title<.*qwen.*>" = "󰚩";
            "class<subl>" = "󰅳";
            "class<slack>" = "";

            "class<mpv>" = "";
            "class<celluloid|Zoom>" = "";
            "class<Cider>" = "󰎆";
            "title<.*Picture-in-Picture.*>" = "";
            "title<.*youtube.*>" = "";
            "class<vlc>" = "󰕼";
            "title<.*cmus.*>" = "";
            "class<.*[Ss]potify.*>" = "";

            "class<virt-manager>" = "";
            "class<.virt-manager-wrapped>" = "";

            "class<VSCode|code-url-handler|code-oss|codium|codium-url-handler|VSCodium>" = "󰨞";
            "class<dev.zed.Zed>" = "󰵁";
            "class<codeblocks>" = "󰅩";
            "title<.*github.*>" = "";
            "class<mousepad>" = "";
            "class<libreoffice-writer>" = "";
            "class<libreoffice-startcenter>" = "󰏆";
            "class<libreoffice-calc>" = "";
            "title<.*nvim ~.*>" = "";
            "title<.*vim.*>" = "";
            "title<.*nvim.*>" = "";
            "title<.*figma.*>" = "";
            "title<.*jira.*>" = "";
            "class<jetbrains-idea>" = "";

            "class<obs|com.obsproject.Studio>" = "";

            "class<polkit-gnome-authentication-agent-1>" = "󰒃";
            "class<nwg-look>" = "";
            "class<[Pp]avucontrol|org.pulseaudio.pavucontrol>" = "󱡫";
            "class<steam>" = "";
            "class<thunar|nemo>" = "󰝰";
            "class<Gparted>" = "";
	    "class<gimp>" = "";
	    "class<emulator>" = "📱";
	    "class<android-studio>" = "";
            "class<org.pipewire.Helvum>" = "󰓃";
            "class<localsend>" = "";
            "class<PrusaSlicer|UltiMaker-Cura|OrcaSlicer>" = "󰹛";
            "class<1Password>" = "󰎤";
          };
          all-outputs = true;
          on-click = "activate";
        };
        
        tray = {
          spacing = 10;
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

        backlight = {
          device = "intel_backlight";
          format = "{icon} {percent}%";
          on-scroll-up = "${lib.getExe pkgs.brightnessctl} set 1%+";
          on-scroll-down = "${lib.getExe pkgs.brightnessctl} set 1%-";
          min-length = 6;
        };

        battery = {
          states = {
            good = 95;
            warning = 30;
            critical = 20;
          };
          format = "{icon}  {capacity}%";
          format-icons = ["" "" "" "" ""];
          format-charging = " {capacity}%";
          format-plugged = " {capacity}%";
          format-alt = "{time} {icon} ";
        };

        power-profiles-daemon = {
          format = "{icon}";
          tooltip-format = "Power profile: {profile}\nDriver: {driver}";
          tooltip = true;
          format-icons = {
            default = " ";
            performance = " ";
            balanced = " ";
            power-saver = " ";
          };
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
            default = [ " " " " " " ];
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
          on-click = "foot nmtui";
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
          ignored-players = [ "librewolf" "vlc" "firefox" "brave" ];
        };
        
        mpd = {
          format = "{stateIcon} {artist} - {title}";
          format-disconnected = "Disconnected ";
          format-stopped = "{stateIcon} {artist} - {title}";
          format-empty = "";
          interval = 1;
          on-click = "${lib.getExe pkgs.mpc} toggle";
          consume-icons = {
            on = " ";
          };
          repeat-icons = {
            on = " ";
          };
          single-icons = {
            on = " 1 ";
          };
          state-icons = {
            paused = " ";
            playing = " ";
          };
          tooltip-format = "MPD (connected)";
          tooltip-format-disconnected = "MPD (disconnected)";
        };

         "custom/dunst" = {
          exec = "waybar-dunst-monitor";
          return-type = "json";
          exec-if = "which dunstctl && which dbus-monitor && which waybar-dunst-monitor";
          # Tooltip is handled by the JSON output, disable Waybar's default
          tooltip = false;
          # Click actions
          on-click = "dunstctl set-paused toggle";   # Left click: Toggle pause
          on-click-middle = "dunstctl history-pop";  # Middle click: Show history
          on-click-right = "dunstctl close-all";    # Right click: Close all
        };
      };
    };
    style = /* css */ ''
      * {
        border: none;
        border-radius: 0px;
        font-family: "JetBrainsMono Nerd Font";
        font-size: 14px;
        min-height: 0;
        opacity: 1.0;
      }

      window#waybar {
          background: none;
      }

      tooltip {
        background: #1a1b26;
        border-radius: 7px;
        border-width: 2px;
        border-style: solid;
        border-color: #11111b;
        opacity: 1.0;
      }

      #workspaces button {
        padding: 5px;
        padding-right: 10px;
        margin-right: 5px;
        /* margin-left: 10px; */
      }

      #workspaces button.active {
        color: #89b4fa;
        background: #1a1b26;
        border-radius: 7px;
      }

      #workspaces button:hover {
        background: #11111b;
        color: #c0caf5;
        border-radius: 7px;
      }

      #window,
      #clock,
      #battery,
      #power-profiles-daemon,
      #mpris,
      #pulseaudio,
      #custom-pacman,
      #network,
      #bluetooth,
      #temperature,
      #workspaces,
      #tray,
      #mpd,
      #custom-pomodoro,
      #cpu,
      #memory,
      #custom-spotify,
      #custom-dunst,
      #modbackground {
        background: #${config.stylix.base16Scheme.base01};
        opacity: 1.0;
        padding: 0px 7px;
        margin-top: 5px;
        /*  margin-bottom: 5px; */
        /* border: 1px solid #b5b0a7; */
      }

      #backlight {
        border-radius: 7px 0px 0px 7px;
        background: #1a1b26;
        opacity: 1.0;
        padding: 0px 7px;
        margin-top: 5px;
        margin-bottom: 6px;
      }

      #pulseaudio {
        color: #89b4fa;
        border-radius: 0px;
        border-left: 0px;
        border-radius: 7px 0px 0px 7px;
        border-right: 0px;
      }

      #pulseaudio.microphone {
        color: #cba6f7;
        border-left: 0px;
        border-right: 0px;
        border-radius: 0px 7px 7px 0px;
        margin-right: 5px;
      }

      #cpu {
        color: #89dceb;
        border-radius: 7px 0px 0px 7px;
      }

      #memory {
        color: #94e2d5;
        border-radius: 0px 7px 7px 0px;
        margin-right: 5px;
      }

      #tray {
        border-radius: 7px;
        margin-right: 5px;
      }

      #workspaces {
        border-radius: 7px;
        margin-left: 5px;
        padding-right: 5px;
        padding-left: 5px;
        opacity: 1.0;
      }

      /* #custom-power_profile { */
      /*   color: #a6e3a1; */
      /*   border-left: 0px; */
      /*   border-right: 0px; */
      /* } */

      #window {
        border-radius: 7px;
        margin-left: 10px;
        opacity: 1.0;
        margin-right: 10px;
      }

      #clock {
        color: #fab387;
        border-radius: 7px;
        /* margin-left: 10px; */
        margin-right: 5px;
        /* margin-left: 5px; */
        padding-right: 0px;
        border-right: 0px;
        opacity: 1.0;

      }

      #network {
        color: #f9e2af;
        border-radius: 7px;
        margin-right: 5px;
        border-left: 0px;
        border-right: 0px;
        opacity: 1.0;
      }

      #bluetooth {
        color: #89b4fa;
        border-radius: 7px;
        margin-right: 5px;
        opacity: 1.0;
      }

      #battery {
        color: #a6e3a1;
        border-radius: 7px 0px 0px 7px;
      }

      #power-profiles-daemon {
        color: #a6e3a1;
        margin-right: 5px;
        border-radius: 0px 7px 7px 0px;
      }

      #custom-spotify {
        border-radius: 7px;
        margin-right: 5px;
        border-right: 0px;
        opacity: 1.0;
      }

      #mpris {
        color: #c0caf5;
        border-radius: 7px;
        margin-right: 5px;
        border-right: 0px;
      }

      #mpris.paused {
        color: #c0caf5;
        border-bottom: 2px solid @yellow;
      }

      #mpd {
        color: #c0caf5;
        border-radius: 7px;
        margin-right: 5px;
        border-right: 0px;
      }

      #mpd.paused {
        color: #c0caf5;
        border-bottom: 2px solid @yellow;
      }

      #custom-dunst {
        color: #FF746C;
        border-radius: 7px;
        margin-right: 5px;
        padding-right: 10px;
        border-right: 0px;
      }
    '';
  };
}
