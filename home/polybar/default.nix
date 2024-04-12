{pkgs, ...}: {
  home.packages = [
    (pkgs.polybar.override {
      pulseSupport = true;
    })
  ];

  xdg.configFile = {
    "polybar/config.ini".source = ./polybar.ini;
    "polybar/launch.sh" = {
      source = ./launch.sh;
      executable = true;
    };
  };
}
