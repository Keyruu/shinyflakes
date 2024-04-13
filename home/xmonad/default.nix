{pkgs, ...}: {
  home.packages = [
    (pkgs.haskellPackages.ghcWithPackages (p:
      with p; [
        xmonad
        xmonad-contrib
        xmonad-extras
      ]))
  ];

  xdg.configFile = {
    "xmonad/xmonad.hs".source = ./xmonad.hs;
  };
}
