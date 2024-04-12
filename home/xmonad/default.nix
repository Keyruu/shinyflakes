{pkgs, ...}: {
#  xsession.windowManager.xmonad = {
#    config = ./xmonad.hs;
#  };
  xdg.configFile = {
    "xmonad/xmonad.hs".source = ./xmonad.hs;
  };
}
