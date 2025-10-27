{ lib, pkgs, ... }:
{
  services.swayidle =
    let
      lockTimeout = 5 * 60; # 300 seconds
      suspendTimeout = 15 * 60; # 900 seconds

      screenLocker = lib.getExe pkgs.hyprlock;

      # Use compositor-agnostic commands for screen power management
      screenOn = "${lib.getExe pkgs.wlopm} --on '*'";
      screenOff = "${lib.getExe pkgs.wlopm} --off '*'";
    in
    {
      enable = true;
      extraArgs = [ ];
      timeouts = [
        {
          timeout = lockTimeout - 5;
          command = "${lib.getExe pkgs.libnotify} 'swayidle' 'Locking soon!' --icon='lock' -t 5000";
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
