{ config, ... }:
{
  programs.ghostty = {
    enable = true;
    enableFishIntegration = true;
    systemd.enable = true;

    settings = {
      font-family = config.user.font;
      font-size = 13;
      background = "#100F0F";
      window-padding-x = 10;
      window-padding-y = 10;
      window-decoration = false;
      keybind = [
        "super+n=new_window"

        # Vim key table
        "ctrl+shift+space=activate_key_table:vim"
        "vim/"
        "vim/j=scroll_page_lines:1"
        "vim/k=scroll_page_lines:-1"
        "vim/ctrl+d=scroll_page_down"
        "vim/ctrl+u=scroll_page_up"
        "vim/ctrl+f=scroll_page_down"
        "vim/ctrl+b=scroll_page_up"
        "vim/shift+j=scroll_page_down"
        "vim/shift+k=scroll_page_up"
        "vim/g>g=scroll_to_top"
        "vim/shift+g=scroll_to_bottom"
        "vim/slash=start_search"
        "vim/n=navigate_search:next"

        # Visual mode (v enters select table)
        "vim/v=activate_key_table:select"
        "vim/y=copy_to_clipboard"

        # Select key table
        "select/"
        "select/h=adjust_selection:left"
        "select/l=adjust_selection:right"
        "select/k=adjust_selection:up"
        "select/j=adjust_selection:down"
        "select/ctrl+d=adjust_selection:page_down"
        "select/ctrl+u=adjust_selection:page_up"
        "select/shift+g=adjust_selection:end"
        "select/g>g=adjust_selection:home"
        "select/0=adjust_selection:beginning_of_line"
        "select/shift+4=adjust_selection:end_of_line"
        "select/y=copy_to_clipboard"
        "select/escape=deactivate_key_table"
        "select/q=deactivate_key_table"
        "select/catch_all=ignore"
        "vim/shift+semicolon=toggle_command_palette"
        "vim/escape=deactivate_key_table"
        "vim/q=deactivate_key_table"
        "vim/i=deactivate_key_table"
        "vim/catch_all=ignore"
      ];
    };
  };
}
