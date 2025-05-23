{pkgs, ...}: {
  programs.yazi = {
    enable = true;
    enableZshIntegration = true;
    plugins = with pkgs.yaziPlugins; {
      smart-enter = smart-enter;
      starship = starship;
    };
    keymap = {
      manager.prepend_keymap = [
        {
          on   = "l";
          run  = "plugin smart-enter";
          desc = "Enter the child directory, or open the file";
        }
        {
          on   = "<Enter>";
          run  = "plugin smart-enter";
          desc = "Enter the child directory, or open the file";
        }
      ];
    };
    settings = {
      opener = {
        open = [
          {
            run = "xdg-open \"$@\"";
            orphan = true;
            desc = "Open";
          }
        ];
      };
    };
  };
}
