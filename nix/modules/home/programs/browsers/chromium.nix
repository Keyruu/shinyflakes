{ pkgs, ... }:
{
  programs.chromium = {
    enable = true;
    package = pkgs.ungoogled-chromium;
    commandLineArgs = [
      # Platform
      "--ozone-platform=wayland"
      "--enable-wayland-ime"

      # Hardware Accel
      "--enable-features=AcceleratedVideoDecodeLinuxGL,AcceleratedVideoEncoder"
    ];
  };

  home.sessionVariables = {
    LIBVA_DRIVER_NAME = "iHD";
  };
}
