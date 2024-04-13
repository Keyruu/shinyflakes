{pkgs, ...}: {
  home.packages = [
    (pkgs.haskellPackages.ghcWithPackages (p:
      with p; [
        xmonad
        xmonad-contrib
        xmonad-extras
      ]))
  ];

  xsession = {
    enable = true;
    windowManager.xmonad = {
      enable = true;
      enableContribAndExtras = true;
      config = ./xmonad.hs;
    };
  };

#  xdg.configFile = {
#    "xmonad/xmonad.hs".source = ./xmonad.hs;
#  };
}
