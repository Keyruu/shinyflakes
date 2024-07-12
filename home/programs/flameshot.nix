{user, ...}: {
  services = {
    flameshot = {
      enable = true;
      settings = {
        General = {
          disabledTrayIcon = true;
          showStartupLaunchMessage = false;
          checkForUpdates = false;
          savePath = "/home/${user}/pictures/screenshots";
        };
      };
    };
  };
}
