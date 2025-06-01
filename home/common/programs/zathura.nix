{
  programs.zathura = {
    enable = true;
    options =
      let
        invisible = "rgba(0, 0, 0, 0.0)";
        background-transparent = "rgba(16, 17, 22, 0.8)";
        background = "rgba(40, 42, 54, 1)";
        foreground = "rgba(248, 248, 242, 1)";
        red = "rgba(255, 85, 85, 1)";
        orange = "rgba(255, 184, 108, 1)";
        selection = "rgba(68, 71, 90, 1)";
        comment = "rgba(98, 114, 164, 1)";
        pink = "rgba(255, 121, 198, 0.5)";
      in
      {
        default-bg = background-transparent;
        default-fg = foreground;

        notification-error-bg = red;
        notification-error-fg = foreground;
        notification-warning-bg = orange;
        notification-warning-fg = selection;
        notification-bg = background;
        notification-fg = foreground;

        completion-bg = background;
        completion-fg = comment;
        completion-group-bg = background;
        completion-group-fg = comment;
        completion-highlight-bg = selection;
        completion-highlight-fg = foreground;

        index-bg = background;
        index-fg = foreground;
        index-active-bg = selection;
        index-active-fg = foreground;

        inputbar-bg = background;
        inputbar-fg = foreground;

        statusbar-bg = background;
        statusbar-fg = foreground;

        highlight-color = orange;
        highlight-active-color = pink;

        render-loading = true;
        render-loading-fg = background;
        render-loading-bg = foreground;

        recolor = true;
        recolor-lightcolor = invisible;
        recolor-darkcolor = foreground;

        window-title-basename = true;
        selection-clipboard = "clipboard";
      };
  };
}
