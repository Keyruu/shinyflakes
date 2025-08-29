{ lib, pkgs, ... }:
let
  smart-splits = pkgs.tmuxPlugins.mkTmuxPlugin {
    pluginName = "smart-splits";
    version = "v2.0.3";
    src = pkgs.fetchFromGitHub {
      owner = "mrjones2014";
      repo = "smart-splits.nvim";
      rev = "v2.0.3";
      sha256 = "sha256-zfuBaSnudCWw0N1XAms9CeVrAuPEAPDXxLLg1rTX7FE=";
    };
  };
in
{
  programs.tmux = {
    enable = true;
    clock24 = true;
    mouse = true;
    extraConfig = ''
      set-option -sa terminal-overrides ",xterm*:Tc"
      set -g mouse on

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
      bind -n M-Left select-pane -L
      bind -n M-Right select-pane -R
      bind -n M-Up select-pane -U
      bind -n M-Down select-pane -D

      # Shift arrow to switch windows
      bind -n S-Left  previous-window
      bind -n S-Right next-window

      # Shift Alt vim keys to switch windows
      bind -n M-H previous-window
      bind -n M-L next-window

      # set vi-mode
      set-window-option -g mode-keys vi
      # keybindings
      bind-key -T copy-mode-vi v send-keys -X begin-selection
      bind-key -T copy-mode-vi C-v send-keys -X rectangle-toggle
      bind-key -T copy-mode-vi y send-keys -X copy-selection-and-cancel

      bind '"' split-window -v -c "#{pane_current_path}"
      bind % split-window -h -c "#{pane_current_path}"

      set -g status-style bg=black,fg=white
      set -g status-left '#[fg=green]#S '
      set -g status-right '#[fg=yellow]#(whoami)@#H #[fg=cyan]%Y-%m-%d %H:%M'
      set -g status-left-length 20
      set -g status-right-length 50
    '';
    plugins = with pkgs.tmuxPlugins; [
      smart-splits
      sensible
      yank
      tmux-which-key
    ];
  };
}
