{pkgs, ...}: {
  xdg.configFile = {
    "xmonad/xmonad.hs".source = ./xmonad.hs;
  };
}
