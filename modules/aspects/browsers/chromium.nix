{ ... }:
{
  den.aspects.browsers.chromium = {
    homeManager =
      { pkgs, ... }:
      {
        programs.chromium = {
          enable = true;
          package = pkgs.chromium;
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
      };
  };
}
