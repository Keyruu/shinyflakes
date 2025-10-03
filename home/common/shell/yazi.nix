{ pkgs, username, ... }:
{
  programs.yazi = {
    enable = true;
    enableZshIntegration = true;
    plugins = with pkgs.yaziPlugins; {
      smart-enter = smart-enter;
      starship = starship;
    };
    keymap = {
      mgr.prepend_keymap = [
        {
          on = "l";
          run = "plugin smart-enter";
          desc = "Enter the child directory, or open the file";
        }
        {
          on = "<Enter>";
          run = "plugin smart-enter";
          desc = "Enter the child directory, or open the file";
        }
      ];
    };
    settings = {
      # preview.cache_dir = "$HOME/.cache/yazi";
      opener = {
        edit = [
          {
            run = "zeditor \"$@\"; ya emit quit";
            desc = "Open in Zed";
          }
        ];
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
