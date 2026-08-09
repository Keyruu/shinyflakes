{ ... }:
{
  den.aspects.apps.lazygit = {
    homeManager =
      {
        user,
        lib,
        ...
      }:
      {
        programs.lazygit = {
          enable = true;
          settings = lib.mkForce {
            gui =
              let
                t = user.theme;
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
      };
  };
}
