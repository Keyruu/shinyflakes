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
          mainMonitor: secondaryMonitor:
          lib.concatStringsSep " && " [
            (moveWorkspace "browse" mainMonitor 1)
            (moveWorkspace "ide" mainMonitor 2)
            (moveWorkspace "term" mainMonitor 3)
            (moveWorkspace "media" secondaryMonitor 1)
            (moveWorkspace "social" secondaryMonitor 2)
          ];

        moveAllWorkspacesToOne =
          monitor:
          lib.concatStringsSep " && " [
            (moveWorkspace "browse" monitor 1)
            (moveWorkspace "ide" monitor 2)
            (moveWorkspace "term" monitor 3)
            (moveWorkspace "media" monitor 4)
            (moveWorkspace "social" monitor 5)
          ];

        homeMonitor = "Huawei Technologies Co., Inc. XWU-CBA 0x00000001";
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
              (moveAllWorkspacesToOne laptopMonitor)
            ];
          };
        }
        {
          profile = {
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
              (moveAllWorkspaces homeMonitor laptopMonitor)
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
                (moveAllWorkspaces workMonitor laptopMonitor)
              ];
            };
        }
        {
          profile = {
            name = "desktop-home";
            outputs = [
              {
                criteria = homeMonitor;
                mode = "2560x1440@143.972Hz";
                position = "0,0";
                scale = 1.0;
              }
            ];
            exec = [
              (moveAllWorkspacesToOne homeMonitor)
            ];
          };
        }
        {
          profile =
            let
              sideMonitor = "DP-2";
            in
            {
              name = "desktop-home";
              outputs = [
                {
                  criteria = homeMonitor;
                  mode = "2560x1440@143.972Hz";
                  position = "0,0";
                  scale = 1.0;
                }
                {
                  criteria = sideMonitor;
                  mode = "1920x1080@60.042Hz";
                  position = "2560,720";
                  scale = 1.0;
                }
              ];
              exec = [
                (moveAllWorkspaces homeMonitor sideMonitor)
              ];
            };
        }
      ];
  };
}
