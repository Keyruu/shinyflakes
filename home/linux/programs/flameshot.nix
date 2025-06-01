{ username, pkgs, ... }:
{
  home.packages = with pkgs; [
    grim
  ];

  services = {
    flameshot = {
      enable = true;
      settings = {
        General = {
          disabledTrayIcon = false;
          showStartupLaunchMessage = false;
          savePath = "/home/${username}/Pictures/screenshots";
        };
      };
    };
  };
}
