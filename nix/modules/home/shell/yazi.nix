{ pkgs, ... }:
{
  programs.yazi = {
    enable = true;
    enableZshIntegration = true;
    plugins = with pkgs.yaziPlugins; {
      inherit smart-enter;
      inherit starship;
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
    initLua = ''
      -- Disable image previews when running inside Neovim terminal
      -- to prevent escape sequence leakage that triggers unwanted key inputs
      if os.getenv("NVIM") then
        require("preview"):set("image", false)
      end
    '';
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
