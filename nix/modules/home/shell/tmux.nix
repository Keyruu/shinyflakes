{ lib, pkgs, ... }:
{
  home.packages = [ pkgs.sesh ];

  xdg.configFile."sesh/sesh.toml".text = ''
    [[session]]
    name = "shinyflakes"
    path = "~/shinyflakes"

    [[session]]
    name = "git"
    path = "~/git"

    [[wildcard]]
    pattern = "~/git/*"
  '';

  programs.tmux = {
    enable = true;
    sensibleOnTop = true;
    terminal = "tmux-256color";
    shell = "${lib.getExe pkgs.fish}";
    extraConfig =
      let
        gray_light = "#D8DEE9";
        gray_medium = "#ABB2BF";
        gray_dark = "#3B4552";
        green_soft = "#A3BE8C";
        blue_muted = "#81A1C1";
        cyan_soft = "#88C0D0";
      in
      # tmux
      ''
        set -g @mode_indicator_empty_prompt ' NORMAL '
        set -g @mode_indicator_prefix_prompt ' PREFIX '
        set -g @mode_indicator_copy_prompt ' COPY '
        set -g @mode_indicator_sync_prompt ' SYNC '
        set -g @mode_indicator_prefix_mode_style 'bg=${blue_muted},fg=${gray_dark}'
        set -g @mode_indicator_copy_mode_style 'bg=${green_soft},fg=${gray_dark}'
        set -g @mode_indicator_sync_mode_style 'bg=${gray_medium},fg=${gray_dark}'
        set -g @mode_indicator_empty_mode_style 'bg=${cyan_soft},fg=${gray_dark}'

        set-option -sa terminal-overrides ",xterm*:Tc"
        set -g focus-events on
        set -g extended-keys on
        set -g extended-keys-format csi-u
        set -g mouse on

        set -g prefix C-b
        bind C-b send-prefix

        set -g detach-on-destroy off
        bind -N "last-session (via sesh)" L run-shell "sesh last"
        bind-key "T" run-shell "sesh connect \"$(sesh list --icons | fzf-tmux -p 80%,70% --no-sort --ansi --border-label ' sesh ' --prompt '⚡  ' --header '  ^a all ^t tmux ^g configs ^x zoxide ^d tmux kill ^f find' --bind 'tab:down,btab:up' --bind 'ctrl-a:change-prompt(⚡  )+reload(sesh list --icons)' --bind 'ctrl-t:change-prompt(🪟  )+reload(sesh list -t --icons)' --bind 'ctrl-g:change-prompt(⚙️  )+reload(sesh list -c --icons)' --bind 'ctrl-x:change-prompt(📁  )+reload(sesh list -z --icons)' --bind 'ctrl-f:change-prompt(🔎  )+reload(fd -H -d 2 -t d -E .Trash . ~)' --bind 'ctrl-d:execute(tmux kill-session -t {2..})+change-prompt(⚡  )+reload(sesh list --icons)' --preview-window 'right:55%' --preview 'sesh preview {}')\""

        bind h select-pane -L
        bind j select-pane -D
        bind k select-pane -U
        bind l select-pane -R

        bind x kill-pane

        bind -r C-h resize-pane -L 5
        bind -r C-j resize-pane -D 5
        bind -r C-k resize-pane -U 5
        bind -r C-l resize-pane -R 5

        bind -r '<' swap-window -t -1\; previous-window
        bind -r '>' swap-window -t +1\; next-window

        set -g base-index 1
        set -g pane-base-index 1
        set-window-option -g pane-base-index 1
        set-option -g renumber-windows on

        bind -n M-H previous-window
        bind -n M-L next-window

        bind -n C-M-x copy-mode

        set-window-option -g mode-keys vi
        bind-key -T copy-mode-vi v send-keys -X begin-selection
        bind-key -T copy-mode-vi C-v send-keys -X rectangle-toggle
        bind-key -T copy-mode-vi y send-keys -X copy-selection-and-cancel
        bind-key -T copy-mode-vi Escape send-keys -X cancel
        bind-key -T copy-mode-vi i send-keys -X cancel
        bind-key -T copy-mode-vi q send-keys -X cancel

        bind '-' split-window -v -c "#{pane_current_path}"
        bind '|' split-window -h -c "#{pane_current_path}"
        bind '"' split-window -v -c "#{pane_current_path}"
        bind '%' split-window -h -c "#{pane_current_path}"

        # ── Which-key menu (C-Space, no prefix needed) ──
        bind -n C-Space display-menu -T " tmux " -x C -y C \
          "─── Windows ───"                          "" "" \
          "New window           (c)"                 c new-window \
          "Split horizontal     (-)"                 - "split-window -v -c '#{pane_current_path}'" \
          "Split vertical       (|)"                 | "split-window -h -c '#{pane_current_path}'" \
          "Next window       (M-L)"                  n next-window \
          "Previous window   (M-H)"                  p previous-window \
          "Select window"                            w choose-tree \
          "Rename window"                            r "command-prompt -I '#W' 'rename-window %%'" \
          "Kill window"                              X "confirm-before -p 'Kill window? (y/n)' kill-window" \
          "" \
          "─── Panes ───"                            "" "" \
          "Left                 (h)"                 h "select-pane -L" \
          "Down                 (j)"                 j "select-pane -D" \
          "Up                   (k)"                 k "select-pane -U" \
          "Right                (l)"                 l "select-pane -R" \
          "Zoom toggle          (z)"                 z "resize-pane -Z" \
          "Swap pane down"                           J "swap-pane -D" \
          "Swap pane up"                             K "swap-pane -U" \
          "Kill pane            (x)"                 x kill-pane \
          "Resize left       (C-h)"                  1 "resize-pane -L 5" \
          "Resize down       (C-j)"                  2 "resize-pane -D 5" \
          "Resize up         (C-k)"                  3 "resize-pane -U 5" \
          "Resize right      (C-l)"                  4 "resize-pane -R 5" \
          "" \
          "─── Sessions ───"                         "" "" \
          "Session picker       (T)"               s "run-shell 'sesh connect \"$(sesh list --icons | fzf-tmux -p 80%,70% --no-sort --ansi --border-label \" sesh \" --prompt \"⚡  \" --preview-window right:55% --preview \"sesh preview {}\")\"'" \
          "New session"                              S "command-prompt -p 'Session name:' 'new-session -s %%'" \
          "Rename session"                           R "command-prompt -I '#S' 'rename-session %%'" \
          "Detach               (d)"                 d detach-client \
          "" \
          "─── Layout ───"                           "" "" \
          "Next layout"                              L next-layout \
          "Even horizontal"                          H "select-layout even-horizontal" \
          "Even vertical"                            V "select-layout even-vertical" \
          "" \
          "─── Other ───"                            "" "" \
          "Copy mode         (C-M-x)"               v copy-mode \
          "Reload config"                            C "source-file ~/.config/tmux/tmux.conf; display 'Config reloaded'" \
          "Command prompt       (:)"                 : command-prompt

        set -g status-position top
        set -g status-left-length 100
        set -g status-style "fg=${gray_light},bg=default"
        set -g status-left "#{tmux_mode_indicator}"
        set-option -g status-justify centre
        set -g status-right "#[fg=${green_soft},bold]#S  #[fg=${gray_medium}](#{server_sessions})"
        set -g window-status-current-format "#[fg=${cyan_soft},bold] #[underscore]#I:#W"
        set -g window-status-format " #I:#W"
        set -g message-style "fg=${gray_light},bold"
        set -g mode-style "fg=${gray_dark},bg=${blue_muted}"
        set -g pane-border-style "fg=${gray_dark}"
        set -g pane-active-border-style "fg=${gray_medium}"

        run-shell ${pkgs.tmuxPlugins.mode-indicator}/share/tmux-plugins/mode-indicator/mode_indicator.tmux
      '';
    plugins = with pkgs.tmuxPlugins; [
      sensible
    ];
  };
}
