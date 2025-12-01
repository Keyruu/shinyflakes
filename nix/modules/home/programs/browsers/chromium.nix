{ pkgs, inputs, ... }:
let
  pkgs-stable = import inputs.nixpkgs-stable { system = pkgs.system; };
in
{
  programs.chromium = {
    enable = true;
    package = pkgs.google-chrome;
    commandLineArgs = [
      # Platform
      "--ozone-platform=wayland"
      "--enable-wayland-ime"

      # Hardware Accel
      "--enable-features=VaapiVideoDecoder,AcceleratedVideoDecodeLinuxGL,AcceleratedVideoEncoder"
      "--ignore-gpu-blocklist"
    ];
  };

  home = {
    sessionVariables = {
      LIBVA_DRIVER_NAME = "iHD";
    };
  };
}
