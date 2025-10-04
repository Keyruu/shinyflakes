{ lib, pkgs, ... }:
{
  programs.swaylock = {
    enable = true;
  };

  programs.hyprlock = {
    enable = true;

    settings = {
      general = {
        hide_cursor = true;
        ignore_empty_input = true;
      };

      auth.fingerprint = {
        enabled = true;
        ready_message = "<span>  </span>";
        present_message = ''<span foreground='##94E2D5'>  </span>'';
      };

      background = [
        {
          path = "screenshot";
          blur_passes = 3;
          blur_size = 8;
        }
      ];

      label = [
        {
          text = "$FPRINTPROMPT";
          font_size = 50;
          position = "-6, 0"; # the unicode symbol is slightly out of center
        }
        {
          text = "$TIME";
          valign = "top";
          halign = "left";
          position = "15, -10";
        }
        {
          text = ''cmd[update:10000] echo "$(${lib.getExe' pkgs.coreutils-full "cat"} /sys/class/power_supply/BAT0/capacity)%"'';
          valign = "top";
          halign = "right";
          position = "-15, -10";
        }
      ];

      input-field = {
        position = "0, -70";
        outline_thickness = 0;
        dots_size = 0.2;
        fade_on_empty = false;
        swap_font_color = true;
        placeholder_text = "";
        font_family = "monospace";
        font_color = "rgba(254, 254, 254, 1.0)";
        inner_color = "rgba(0, 0, 0, 0.0)";
        check_color = "rgba(148, 226, 213, 1.0)";
      };
    };
  };

  services.swayidle =
    let
      lockTimeout = 5 * 60; # 300 seconds
      suspendTimeout = 15 * 60; # 900 seconds

      screenLocker = lib.getExe pkgs.hyprlock;

      screenOn = "${lib.getExe pkgs.wlopm} --on '*'";
      screenOff = "${lib.getExe pkgs.wlopm} --off '*'";
    in
    {
      enable = true;
      extraArgs = [ ];
      timeouts = [
        {
          timeout = lockTimeout - 5;
          command = "${lib.getExe pkgs.libnotify} 'Locking in 5 seconds' -t 5000";
        }
        {
          timeout = lockTimeout; # 300 seconds (5 minutes)
          command = "${lib.getExe' pkgs.systemd "loginctl"} lock-session";
        }
        {
          timeout = lockTimeout + 10;
          command = screenOff;
          resumeCommand = screenOn;
        }
        {
          timeout = suspendTimeout; # 900 seconds (15 minutes)
          command = "${lib.getExe' pkgs.systemd "systemctl"} suspend";
          resumeCommand = screenOn;
        }
      ];
      events = [
        {
          event = "before-sleep";
          command = "${lib.getExe' pkgs.systemd "loginctl"} lock-session";
        }
        {
          event = "lock";
          command = "${lib.getExe' pkgs.procps "pidof"} hyprlock || ${screenLocker}";
        }
        {
          event = "unlock";
          command = screenOn;
        }
        {
          event = "after-resume";
          command = screenOn;
        }
      ];
    };
}
