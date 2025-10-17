{ lib, pkgs, ... }:
{
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
      ''
        set -g @tmux-which-key-xdg-enable 1
        set -g @tmux-which-key-disable-autobuild 1
        # run-shell ${pkgs.tmuxPlugins.tmux-which-key}/share/tmux-plugins/tmux-which-key/plugin.sh.tmux

        set -g @mode_indicator_empty_prompt ' NORMAL '
        set -g @mode_indicator_prefix_prompt ' PREFIX '
        set -g @mode_indicator_copy_prompt ' COPY '
        set -g @mode_indicator_sync_prompt ' SYNC '
        set -g @mode_indicator_prefix_mode_style 'bg=blue,fg=black'
        set -g @mode_indicator_copy_mode_style 'bg=yellow,fg=black'
        set -g @mode_indicator_sync_mode_style 'bg=red,fg=black'
        set -g @mode_indicator_empty_mode_style 'bg=cyan,fg=black'

        set-option -sa terminal-overrides ",xterm*:Tc"
        set -g mouse on

        # unbind C-b
        # set -g prefix C-Space
        # bind C-Space send-prefix

        # Vim style pane selection
        bind h select-pane -L
        bind j select-pane -D
        bind k select-pane -U
        bind l select-pane -R

        # Start windows and panes at 1, not 0
        set -g base-index 1
        set -g pane-base-index 1
        set-window-option -g pane-base-index 1
        set-option -g renumber-windows on

        # Use Alt-arrow keys without prefix key to switch panes
        bind -n C-Left select-pane -L
        bind -n C-Right select-pane -R
        bind -n C-Up select-pane -U
        bind -n C-Down select-pane -D

        # Shift arrow to switch windows
        bind -n C-Left  previous-window
        bind -n C-Right next-window

        # Shift Alt vim keys to switch windows
        bind -n M-H previous-window
        bind -n M-L next-window

        bind -n C-M-x copy-mode

        # set vi-mode
        set-window-option -g mode-keys vi
        # keybindings
        bind-key -T copy-mode-vi v send-keys -X begin-selection
        bind-key -T copy-mode-vi C-v send-keys -X rectangle-toggle
        bind-key -T copy-mode-vi y send-keys -X copy-selection-and-cancel
        bind-key -T copy-mode-vi Escape send-keys -X cancel
        bind-key -T copy-mode-vi i send-keys -X cancel
        bind-key -T copy-mode-vi q send-keys -X cancel

        bind '"' split-window -v -c "#{pane_current_path}"
        bind % split-window -h -c "#{pane_current_path}"

        set -g status-position top
        set -g status-left-length 100
        set -g status-style "fg=${gray_light},bg=default"
        set -g status-left "#[fg=${green_soft},bold] #S"
        set-option -g status-justify centre
        set -g status-right "#{tmux_mode_indicator}"
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
