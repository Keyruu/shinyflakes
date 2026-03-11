{
  pkgs,
  lib,
  ...
}:
let
  tomlFormat = pkgs.formats.toml { };

  yaziPlugins = with pkgs.yaziPlugins; {
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

  settings = {
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

  nvimSettings = lib.recursiveUpdate settings {
    plugin = {
      prepend_previewers = [
        {
          mime = "image/*";
          run = "noop";
        }
        {
          mime = "image/{avif,hei?,jxl}";
          run = "noop";
        }
        {
          mime = "application/pdf";
          run = "noop";
        }
      ];
      prepend_preloaders = [
        {
          mime = "image/*";
          run = "noop";
        }
        {
          mime = "image/{avif,hei?,jxl}";
          run = "noop";
        }
        {
          mime = "application/pdf";
          run = "noop";
        }
      ];
    };
  };
in
{
  programs.yazi = {
    enable = true;
    enableZshIntegration = true;
    plugins = yaziPlugins;
    inherit keymap settings;
  };

  xdg.configFile = {
    "yazi-nvim/yazi.toml".source = tomlFormat.generate "yazi-nvim-settings" nvimSettings;
    "yazi-nvim/keymap.toml".source = tomlFormat.generate "yazi-nvim-keymap" keymap;
  }
  // lib.mapAttrs' (
    name: value: lib.nameValuePair "yazi-nvim/plugins/${name}.yazi" { source = value; }
  ) yaziPlugins;
}
