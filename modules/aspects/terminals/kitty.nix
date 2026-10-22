{ ... }:
{
  den.aspects.terminals.kitty = {
    homeManager =
      {
        config,
        user,
        pkgs,
        lib,
        self',
        ...
      }:
      {
        programs.kitty = {
          enable = true;

          shellIntegration = {
            enableFishIntegration = true;
            enableZshIntegration = true;
          };

          themeFile = "Dracula";

          settings = {
            shell = lib.getExe pkgs.fish;
            enabled_layouts = "splits,stack";
            tab_bar_edge = "top";
            tab_bar_min_tabs = 1;
            active_tab_title_template = "{('[' + keyboard_mode.upper() + ' · ? help] ') if keyboard_mode else ''}{index}: {title}";
            window_margin_width = 0;
            window_border_width = "1px";
            hide_window_decorations = "titlebar-only";
            tab_bar_style = "powerline";
            background_blur = "1";
            background_opacity = "0.9";
            enable_audio_bell = "false";
            visual_bell_duration = "0.2";
            visual_bell_color = "#003753";
            font_family = user.theme.font;
            font_size = "13";
            scrollback_lines = "10000";
            scrollback_pager = lib.getExe self'.packages.nvim-scrollback;
          };

          keybindings = {
            "super+n" = "new_os_window_with_cwd";
            "alt+h" = "previous_tab";
            "alt+l" = "next_tab";
            "alt+n" = "launch --cwd=current --location=split";
            "alt+i" = "move_tab_backward";
            "alt+o" = "move_tab_forward";
            "alt+equal" = "resize_window wider";
            "alt+minus" = "resize_window narrower";
            "alt+[" = "last_used_layout";
            "alt+]" = "next_layout";
            "alt+g" = "launch --cwd=current --type=overlay ${lib.getExe pkgs.lazygit}";
            "alt+s" = "goto_session";
          };

          # After theme so it overrides Dracula's #282a36 background
          extraConfig = ''
            background #100F0F

            # Ending the prefix also removes it when it pushes a persistent submode.
            map --new-mode prefix --on-action end ctrl+space
            map --mode prefix c new_tab_with_cwd
            map --mode prefix x close_window
            map --mode prefix z toggle_layout stack
            map --mode prefix h neighboring_window left
            map --mode prefix j neighboring_window down
            map --mode prefix k neighboring_window up
            map --mode prefix l neighboring_window right
            map --mode prefix - launch --cwd=current --location=hsplit
            map --mode prefix | launch --cwd=current --location=vsplit
            map --mode prefix v show_scrollback
            # Open a fresh project window instead of replacing running programs.
            map --mode prefix shift+d launch --cwd=current --type=background ${lib.getExe pkgs.kitty} --session ${config.xdg.configHome}/kitty/project.kitty-session

            map --mode prefix --new-mode pane p
            map --mode pane p pop_keyboard_mode
            map --mode pane h neighboring_window left
            map --mode pane j neighboring_window down
            map --mode pane k neighboring_window up
            map --mode pane l neighboring_window right
            map --mode pane tab nth_window -1
            map --mode pane n combine : pop_keyboard_mode : launch --cwd=current --location=split
            map --mode pane d combine : pop_keyboard_mode : launch --cwd=current --location=hsplit
            map --mode pane r combine : pop_keyboard_mode : launch --cwd=current --location=vsplit
            map --mode pane x combine : pop_keyboard_mode : close_window
            map --mode pane f combine : pop_keyboard_mode : toggle_layout stack
            map --mode pane c combine : pop_keyboard_mode : set_window_title

            map --mode prefix --new-mode tab t
            map --mode tab t pop_keyboard_mode
            map --mode tab h previous_tab
            map --mode tab k previous_tab
            map --mode tab j next_tab
            map --mode tab l next_tab
            map --mode tab tab goto_tab -1
            map --mode tab r combine : pop_keyboard_mode : set_tab_title
            map --mode tab n combine : pop_keyboard_mode : new_tab_with_cwd
            map --mode tab x combine : pop_keyboard_mode : close_tab
            map --mode tab b combine : pop_keyboard_mode : detach_window new-tab
            map --mode tab ] combine : pop_keyboard_mode : detach_window tab-right
            map --mode tab [ combine : pop_keyboard_mode : detach_window tab-left

            map --mode prefix --new-mode resize r
            map --mode resize r pop_keyboard_mode
            map --mode resize h resize_window wider
            map --mode resize l resize_window wider
            map --mode resize j resize_window taller
            map --mode resize k resize_window taller
            map --mode resize shift+h resize_window narrower
            map --mode resize shift+l resize_window narrower
            map --mode resize shift+j resize_window shorter
            map --mode resize shift+k resize_window shorter
            map --mode resize = resize_window wider
            map --mode resize - resize_window narrower

            map --mode prefix --new-mode move m
            map --mode move m pop_keyboard_mode
            map --mode move h move_window left
            map --mode move j move_window down
            map --mode move k move_window up
            map --mode move l move_window right
            map --mode move n move_window_forward
            map --mode move tab move_window_forward
            map --mode move p move_window_backward

            map --mode prefix --new-mode scroll s
            map --mode scroll s pop_keyboard_mode
            map --mode scroll j scroll_line_down
            map --mode scroll k scroll_line_up
            map --mode scroll h scroll_page_up
            map --mode scroll l scroll_page_down
            map --mode scroll ctrl+b scroll_page_up
            map --mode scroll ctrl+f scroll_page_down
            map --mode scroll u remote_control scroll-window 0.5p-
            map --mode scroll d remote_control scroll-window 0.5p
            map --mode scroll e combine : pop_keyboard_mode : show_scrollback
            map --mode scroll f combine : pop_keyboard_mode : search_scrollback
            map --mode scroll ctrl+c combine : pop_keyboard_mode : scroll_end

            map --mode prefix --new-mode session o
            map --mode session o pop_keyboard_mode
            map --mode session w combine : pop_keyboard_mode : goto_session
            map --mode session s combine : pop_keyboard_mode : save_as_session
            map --mode session c combine : pop_keyboard_mode : load_config_file
          ''
          +
            lib.concatMapStrings
              (mode: ''
                map --mode ${mode} esc pop_keyboard_mode
                map --mode ${mode} enter pop_keyboard_mode
                map --mode ${mode} ctrl+space pop_keyboard_mode
                map --mode ${mode} ? combine : pop_keyboard_mode : command_palette
              '')
              [
                "prefix"
                "pane"
                "tab"
                "resize"
                "move"
                "scroll"
                "session"
              ]
          + lib.concatMapStrings (n: ''
            map --mode tab ${toString n} combine : pop_keyboard_mode : goto_tab ${toString n}
          '') (lib.range 1 9);
        };

        # No startup_session: ordinary Kitty windows stay shells during the trial.
        xdg.configFile."kitty/project.kitty-session".text = ''
          layout splits
          launch --var project_editor=1 nvim
          launch --location=vsplit --bias=40 pi
          focus_matching_window var:project_editor=1
          launch --location=hsplit --bias=30
          focus_matching_window var:project_editor=1
        '';
      };
  };
}
