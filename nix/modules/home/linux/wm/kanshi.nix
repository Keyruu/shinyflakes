{ ... }:
{
  services.kanshi = {
    enable = true;
    systemdTarget = "niri.service";
    settings = [
      {
        profile = {
          name = "laptop";
          outputs = [
            {
              criteria = "eDP-1";
              mode = "1920x1200@60Hz";
              position = "0,0";
              scale = 1.0;
            }
          ];
        };
      }
      {
        profile = {
          name = "laptop-home";
          outputs = [
            {
              criteria = "eDP-1";
              mode = "1920x1200@60Hz";
              position = "0,0";
              scale = 1.0;
            }
            {
              criteria = "Huawei Technologies Co., Inc. XWU-CBA 0x00000001";
              mode = "2560x1440@143.972Hz";
              position = "-320,-1440";
              scale = 1.0;
            }
          ];
          exec = [
            "niri msg action move-workspace-to-monitor --reference browse 'Huawei Technologies Co., Inc. XWU-CBA 0x00000001'"
            "niri msg action move-workspace-to-monitor --reference ide 'Huawei Technologies Co., Inc. XWU-CBA 0x00000001'"
            "niri msg action move-workspace-to-monitor --reference term 'Huawei Technologies Co., Inc. XWU-CBA 0x00000001'"
            "systemctl restart --user ironbar"
          ];
        };
      }
      {
        profile = {
          name = "laptop-work";
          outputs = [
            {
              criteria = "eDP-1";
              mode = "1920x1200@60Hz";
              position = "0,0";
              scale = 1.0;
            }
            {
              criteria = "LG Electronics LG HDR 4K 0x00073A91";
              mode = "3840x2160@59.997";
              position = "-411,-1543";
              scale = 1.4;
            }
          ];
          exec = [
            "niri msg action move-workspace-to-monitor --reference browse 'LG Electronics LG HDR 4K 0x00073A91'"
            "niri msg action move-workspace-to-monitor --reference ide 'LG Electronics LG HDR 4K 0x00073A91'"
            "niri msg action move-workspace-to-monitor --reference term 'LG Electronics LG HDR 4K 0x00073A91'"
            "systemctl restart --user ironbar"
          ];
        };
      }
    ];
  };
}
