{ ... }:
{
  den.aspects.terminals.kitty = {
    homeManager =
      {
        user,
        lib,
        self',
        ...
      }:
      {
        xdg.configFile."xdg-terminals.list".text = ''
          kitty.desktop
        '';

        programs.kitty = {
          enable = true;

          shellIntegration = {
            enableFishIntegration = true;
            enableZshIntegration = true;
          };

          themeFile = "Dracula";

          settings = {
            window_margin_width = 0;
            window_padding_width = 10;
            window_border_width = "1px";
            hide_window_decorations = "titlebar-only";
            background_blur = "1";
            background_opacity = "0.9";
            enable_audio_bell = "false";
            visual_bell_duration = "0.2";
            visual_bell_color = "#003753";
            cursor_trail = 3;
            cursor_trail_decay = "0.1 0.4";
            cursor_trail_start_threshold = 10;
            font_family = user.theme.font;
            font_size = "13";
            scrollback_lines = "10000";
            scrollback_pager = lib.getExe self'.packages.nvim-scrollback;
          };

          keybindings = {
            "super+n" = "new_os_window_with_cwd";
            "ctrl+shift+space" = "show_scrollback";
          };

          # After theme so it overrides Dracula's #282a36 background
          extraConfig = ''
            background #100F0F
          '';
        };
      };
  };
}
