{ lib, ... }:
{
  services.kanshi = {
    enable = true;
    systemdTarget = "niri.service";
    settings =
      let
        moveToMonitor =
          workspace: monitor:
          "niri msg action move-workspace-to-monitor --reference ${workspace} '${monitor}'";
        moveWorkspaceToIndex =
          workspace: index:
          "niri msg action move-workspace-to-index --reference ${workspace} ${toString index}";
        moveWorkspace =
          workspace: monitor: index:
          "${moveToMonitor workspace monitor} && ${moveWorkspaceToIndex workspace index}";

        moveAllWorkspaces =
          monitor:
          lib.concatStringsSep " && " [
            (moveWorkspace "browse" monitor 1)
            (moveWorkspace "ide" monitor 2)
            (moveWorkspace "term" monitor 3)
          ];

        laptopMonitor = "eDP-1";
        laptopOutput = {
          criteria = laptopMonitor;
          mode = "1920x1200@60Hz";
          position = "0,0";
          scale = 1.0;
        };
      in
      [
        {
          profile = {
            name = "laptop";
            outputs = [
              laptopOutput
            ];
            exec = [
              (moveAllWorkspaces laptopMonitor)
            ];
          };
        }
        {
          profile =
            let
              homeMonitor = "Huawei Technologies Co., Inc. XWU-CBA 0x00000001";
            in
            {
              name = "laptop-home";
              outputs = [
                laptopOutput
                {
                  criteria = homeMonitor;
                  mode = "2560x1440@143.972Hz";
                  position = "-320,-1440";
                  scale = 1.0;
                }
              ];
              exec = [
                (moveAllWorkspaces homeMonitor)
              ];
            };
        }
        {
          profile =
            let
              workMonitor = "LG Electronics LG HDR 4K 0x00073A91";
            in
            {
              name = "laptop-work";
              outputs = [
                laptopOutput
                {
                  criteria = workMonitor;
                  mode = "3840x2160@59.997";
                  position = "-411,-1543";
                  scale = 1.4;
                }
              ];
              exec = [
                (moveAllWorkspaces workMonitor)
              ];
            };
        }
      ];
  };
}
