{ pkgs, ... }:
{
  environment.systemPackages = [
    (pkgs.appimage-run.override {
      extraPkgs = _: [
        pkgs.xcb-util-cursor
      ];
    })
  ];

  programs.appimage.enable = true;
}
