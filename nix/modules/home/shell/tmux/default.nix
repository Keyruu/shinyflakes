{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib)
    concatMap
    concatStringsSep
    foldl'
    genList
    isString
    optional
    stringLength
    ;
  inherit (builtins) replaceStrings;

  t = config.user.theme;

  # Toggle a single tagged pane per session. Spawn / hide (detach as
  # background window) / restore to current window. Tagged via a
  # pane-option so the marker survives shell restarts/clears.
  mkToggle =
    {
      name,
      tag,
      split,
      size,
      windowName,
      cmd ? "",
      full ? false,
    }:
    let
      fullFlag = lib.optionalString full "-f";
    in
    pkgs.writeShellScript "tmux-${name}-toggle" ''
      set -e
      target=$(tmux list-panes -s -F '#{pane_id} #{window_id} #{@${tag}}' \
        | awk '$3==1 {print $1, $2; exit}')
      if [ -z "$target" ]; then
        tmux split-window ${fullFlag} ${split} -l ${size} -c "#{pane_current_path}" ${cmd}
        tmux set -p @${tag} 1
        exit 0
      fi
      pane_id=$(echo "$target" | awk '{print $1}')
      win_id=$(echo "$target" | awk '{print $2}')
      cur_win=$(tmux display -p '#{window_id}')
      if [ "$win_id" = "$cur_win" ]; then
        # -n names the stashed bg window so toggles are distinguishable
        # in the window list while hidden.
        tmux break-pane -d -n ${lib.escapeShellArg windowName} -s "$pane_id"
      else
        tmux join-pane ${fullFlag} ${split} -l ${size} -s "$pane_id"
      fi
    '';

  piToggle = mkToggle {
    name = "pi";
    tag = "is_pi";
    windowName = "[pi]";
    split = "-h";
    size = "40%";
    cmd = "pi";
    full = true;
  };

  termToggle = mkToggle {
    name = "term";
    tag = "is_nvim_term";
    windowName = "[term]";
    split = "-v";
    size = "30%";
  };

  seshPicker = pkgs.writeShellScript "tmux-sesh-picker" ''
    set -e
    sel=$(sesh list --icons | fzf-tmux -p 80%,70% \
      --no-sort --ansi \
      --border-label ' sesh ' \
      --prompt '⚡  ' \
      --preview-window right:55% \
      --preview 'sesh preview {}')
    [ -n "$sel" ] && sesh connect "$sel"
  '';

  menu = import ./menu.nix { inherit pkgs seshPicker; };
  allEntries = concatMap (category: category.commands) menu;

  # display-menu takes one arg per token; always wrap each arg in "..." so
  # #{...} format strings, spaces, and special chars survive.
  quote = str: "\"" + (replaceStrings [ "\"" ] [ "\\\"" ] str) + "\"";

  # Normalize bind shorthand: a bare string means `{ key = <string>; }`.
  normalizeBind = bind: if isString bind then { key = bind; } else bind;

  mkBind =
    command: rawBind:
    let
      bind = normalizeBind rawBind;
      repeat = if (bind.repeat or false) then "-r " else "";
      flag = if (bind ? flag) then "${bind.flag} " else "";
    in
    "bind ${repeat}${flag}'${bind.key}' ${command}";

  bindLines = concatStringsSep "\n        " (
    concatMap (entry: map (mkBind entry.command) (entry.bind or [ ])) allEntries
  );

  # Pad labels to a common width so the hint column lines up in the menu.
  maxLabelLen = foldl' (
    acc: entry: if stringLength entry.label > acc then stringLength entry.label else acc
  ) 0 allEntries;
  padRight =
    str:
    let
      padding = maxLabelLen - stringLength str;
    in
    str + concatStringsSep "" (genList (_: " ") (if padding < 0 then 0 else padding));

  renderEntry =
    entry:
    let
      label = if entry ? hint then "${padRight entry.label}  (${entry.hint})" else entry.label;
    in
    "${quote label} ${quote entry.key} ${quote entry.command}";

  renderSection =
    index: category:
    let
      header = ''${quote "─── ${category.title} ───"} "" ""'';
      entries = map renderEntry category.commands;
    in
    (optional (index > 0) "\"\"") ++ [ header ] ++ entries;

  menuArgs = concatStringsSep " \\\n          " (
    concatMap (index: renderSection index (builtins.elemAt menu index)) (genList (index: index) (builtins.length menu))
  );
in
{
  imports = [ ./sesh.nix ];

  programs.tmux = {
    enable = true;
    sensibleOnTop = true;
    terminal = "tmux-256color";
    shell = "${lib.getExe pkgs.fish}";
    extraConfig =
      # tmux
      ''
        set -g @mode_indicator_empty_prompt ' TMUX '
        set -g @mode_indicator_prefix_prompt ' PREFIX '
        set -g @mode_indicator_copy_prompt ' COPY '
        set -g @mode_indicator_sync_prompt ' SYNC '
        set -g @mode_indicator_prefix_mode_style 'bg=${t.colors.blue},fg=${t.onAccent}'
        set -g @mode_indicator_copy_mode_style 'bg=${t.colors.green},fg=${t.onAccent}'
        set -g @mode_indicator_sync_mode_style 'bg=${t.muted},fg=${t.onAccent}'
        set -g @mode_indicator_empty_mode_style 'bg=${t.accent},fg=${t.onAccent}'

        set-option -sa terminal-overrides ",xterm*:Tc"
        set -g focus-events on
        set -g extended-keys on
        set -g extended-keys-format csi-u
        # Declare that the outer terminal can carry extended-key sequences,
        # so tmux actually forwards modifyOtherKeys / kitty-kbd to apps that
        # request them (e.g. pi's TUI needs this for Shift+Enter).
        set -as terminal-features '*:extkeys'
        set -g mouse on

        set -g history-limit 100000
        set -g allow-passthrough on

        set -g prefix C-b
        bind C-b send-prefix

        set -g detach-on-destroy off
        bind -N "last-session (via sesh)" L run-shell "sesh last"

        # smart-splits.nvim: C-h/j/k/l navigates nvim splits and tmux panes
        bind-key -n C-h if-shell -F '#{@pane-is-vim}' 'send-keys C-h' 'select-pane -L'
        bind-key -n C-j if-shell -F '#{@pane-is-vim}' 'send-keys C-j' 'select-pane -D'
        bind-key -n C-k if-shell -F '#{@pane-is-vim}' 'send-keys C-k' 'select-pane -U'
        bind-key -n C-l if-shell -F '#{@pane-is-vim}' 'send-keys C-l' 'select-pane -R'
        # In copy-mode, plain tmux navigation (no nvim forwarding needed)
        bind-key -T copy-mode-vi C-h select-pane -L
        bind-key -T copy-mode-vi C-j select-pane -D
        bind-key -T copy-mode-vi C-k select-pane -U
        bind-key -T copy-mode-vi C-l select-pane -R

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
        bind-key -T copy-mode-vi y send-keys -X copy-selection-no-clear \; display-message "yanked"
        bind-key -T copy-mode-vi Escape send-keys -X cancel
        bind-key -T copy-mode-vi i send-keys -X cancel
        bind-key -T copy-mode-vi q send-keys -X cancel

        set -s command-alias[100] pi-toggle='run-shell ${piToggle}'
        set -s command-alias[101] term-toggle='run-shell ${termToggle}'
        set -s command-alias[102] lazygit-toggle='display-popup -E -d "#{pane_current_path}" -w 90% -h 90% -T " lazygit " ${lib.getExe pkgs.lazygit}'

        ${bindLines}

        set -g @extrakto_key 'e'
        set -g @extrakto_grab_area 'window 500'
        set -g @extrakto_filter_order 'path/url line quote s-quote word all'
        set -g @extrakto_default_opt 'insert'
        set -g @extrakto_popup_size '90%'

        bind -n C-Space display-menu -T " tmux " -x C -y C \
          ${menuArgs}

        set -g status-position top
        set -g status-left-length 100
        set -g status-style "fg=${t.foreground},bg=default"
        set -g status-left "#{tmux_mode_indicator}"
        set-option -g status-justify centre
        set -g status-right "#[fg=${t.colors.green},bold]#S  #[fg=${t.muted}](#{server_sessions})"
        set -g window-status-current-format "#[fg=${t.accent},bold] #[underscore]#I:#W#{?window_zoomed_flag, 🔍,}"
        set -g window-status-format " #I:#W"
        set -g message-style "fg=${t.foreground},bold"
        set -g mode-style "fg=${t.onAccent},bg=${t.colors.blue}"
        set -g pane-border-style "fg=${t.muted}"
        set -g pane-active-border-style "fg=${t.accent},bold"
        set -g popup-border-style "fg=${t.accent}"
        set -g popup-border-lines rounded
        set -g menu-border-style "fg=${t.accent}"
        set -g menu-border-lines rounded
        set -g menu-selected-style "fg=${t.onAccent},bg=${t.accent},bold"
        # Show per-pane title (set via `select-pane -T <name>`) on the top border.
        set -g pane-border-status top
        set -g pane-border-format " #{?pane_title,#{pane_title},#{pane_current_command}} "
        # Auto-rename pi/term toggle panes for clarity.
        set-hook -g after-split-window 'select-pane -T "#{pane_current_command}"'

        run-shell ${pkgs.tmuxPlugins.mode-indicator}/share/tmux-plugins/mode-indicator/mode_indicator.tmux
      '';
    plugins = with pkgs.tmuxPlugins; [
      sensible
      extrakto
    ];
  };
}
