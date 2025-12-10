{
  config,
  lib,
  pkgs,
  ...
}:
{
  services.swayidle =
    let
      lockTimeout = 5 * 60; # 300 seconds
      suspendTimeout = 15 * 60; # 900 seconds

      screenOn = "${lib.getExe' pkgs.niri-unstable "niri"} msg action power-on-monitors";
      screenOff = "${lib.getExe' pkgs.niri-unstable "niri"} msg action power-off-monitors";
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
      events = {
        before-sleep = "${lib.getExe' pkgs.systemd "loginctl"} lock-session";
        lock = "${config.programs.noctalia-shell.package}/bin/noctalia-shell ipc call lockScreen lock";
        unlock = screenOn;
        after-resume = screenOn;
      };
    };
}
