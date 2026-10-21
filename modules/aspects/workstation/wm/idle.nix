{ ... }:
{
  den.aspects.workstation.wm.idle = {
    homeManager =
      {
        lib,
        pkgs,
        ...
      }:
      {
        services.swayidle =
          let
            lockTimeout = 5 * 60;
            suspendTimeout = 15 * 60;

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
                timeout = lockTimeout;
                command = "${lib.getExe' pkgs.systemd "loginctl"} lock-session";
              }
              {
                timeout = lockTimeout + 10;
                command = screenOff;
                resumeCommand = screenOn;
              }
              {
                timeout = suspendTimeout;
                command = "${lib.getExe' pkgs.systemd "systemctl"} suspend";
                resumeCommand = screenOn;
              }
            ];
            events = {
              before-sleep = "${lib.getExe' pkgs.systemd "loginctl"} lock-session";
              lock = lib.getExe pkgs.hyprlock;
              unlock = screenOn;
              after-resume = screenOn;
            };
          };
      };
  };
}
