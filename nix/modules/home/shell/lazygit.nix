{ config, lib, ... }:
{
  programs.lazygit = {
    enable = true;
    settings = lib.mkForce {
      gui =
        let
          t = config.user.theme;
        in
        {
          theme = {
            activeBorderColor = [
              t.accent
              "bold"
            ];
            inactiveBorderColor = [ t.muted ];
            selectedLineBgColor = [ t.surface ];
          };
          showListFooter = false;
          showRandomTip = false;
          showCommandLog = false;
          showBottomLine = false;
          nerdFontsVersion = "3";
        };
    };
  };
}
