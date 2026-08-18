{ lib, ... }:
{
  den.aspects.options.kanshi.monitors.homeManager = { ... }: {
    # Registry of physical monitors for the home-manager graph. Only users
    # that opt in get this option defined; servers don't. Each entry holds
    # only intrinsic bits (criteria/mode/scale); layout (position) lives on
    # the host's `displays` config because it depends on where the monitor
    # sits when docked. `tuxedo` was dropped when `lighter` was retired.
    options.monitors = lib.mkOption {
      type = lib.types.attrsOf (lib.types.submodule {
        options = {
          criteria = lib.mkOption {
            type = lib.types.str;
            description = "wlroots output criterion to match this monitor.";
          };
          mode = lib.mkOption {
            type = lib.types.str;
            default = "";
            description = "Preferred mode string, e.g. \"2560x1440@143.972Hz\".";
          };
          scale = lib.mkOption {
            type = lib.types.float;
            default = 1.0;
          };
        };
      });
      default = {
        laptop = {
          criteria = "eDP-1";
          mode = "1920x1200@60Hz";
          scale = 1.0;
        };
        home = {
          criteria = "Huawei Technologies Co., Inc. XWU-CBA 0x00000001";
          mode = "2560x1440@143.972Hz";
          scale = 1.0;
        };
        work = {
          criteria = "LG Electronics LG HDR 4K 0x00073A91";
          mode = "3840x2160@59.997";
          scale = 1.4;
        };
        side = {
          criteria = "DP-2";
          mode = "1920x1080@60.042Hz";
          scale = 1.0;
        };
      };
    };
  };
}
