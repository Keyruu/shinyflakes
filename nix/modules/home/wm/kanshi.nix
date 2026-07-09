{ pkgs, ... }:
{
  # Reload kanshi after resume from suspend/hibernate. Without this, monitor
  # hotplug events on wake are sometimes missed and profiles don't re-apply
  # until the cable is replugged.
  systemd.user.services.kanshi-resume = {
    Unit = {
      Description = "Reload kanshi after resume";
      After = [
        "sleep.target"
        "suspend.target"
        "hibernate.target"
        "hybrid-sleep.target"
        "suspend-then-hibernate.target"
      ];
      Requisite = [ "kanshi.service" ];
    };
    Service = {
      Type = "oneshot";
      ExecStart = "${pkgs.kanshi}/bin/kanshictl reload";
    };
    Install.WantedBy = [
      "sleep.target"
      "suspend.target"
      "hibernate.target"
      "hybrid-sleep.target"
      "suspend-then-hibernate.target"
    ];
  };

  xdg.desktopEntries.kanshi-reload = {
    name = "Reload Kanshi";
    comment = "Re-evaluate kanshi profiles";
    exec = "${pkgs.kanshi}/bin/kanshictl reload";
    icon = "preferences-desktop-display";
    terminal = false;
    categories = [ "Utility" ];
  };

  services.kanshi = {
    enable = true;
    systemdTarget = "graphical-session.target";
  };
}
