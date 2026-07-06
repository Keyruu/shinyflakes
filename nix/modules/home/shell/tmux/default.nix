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

  # Find the pane tagged @is_pi in the current session, or empty if none.
  findPiPane = "$(tmux list-panes -s -F '#{pane_id} #{@is_pi}' | awk '$2==1 {print $1; exit}')";

  # Staging-file workflow: A/Y accumulate into one file per tmux session,
  # S flushes it into the pi pane as one bracketed paste, X discards.
  # Nothing reaches pi until S, so the user can read pi's scrollback and
  # incrementally collect remarks without anything submitting prematurely.
  piStagePath = "/tmp/tmux-pi-prompt-$(tmux display -p '#{session_id}' | tr -d '$').txt";

  piPromptEdit = pkgs.writeShellScript "tmux-pi-prompt-edit" ''
    set -e
    stage=${piStagePath}
    touch "$stage"
    pane=${findPiPane}
    editor="''${EDITOR:-${lib.getExe pkgs.neovim}}"
    if [ -n "$pane" ]; then
      # Split below the pi pane so its output stays visible while editing.
      # Tag the new pane with @is_pi_stage so tool-guardian's nvim-pane
      # detection skips it — we don't want diffs popping up here.
      stage_pane=$(tmux split-window -v -l 20% -t "$pane" -P -F '#{pane_id}' \
        -e "PI_STAGE_FILE=$stage" \
        "$editor '$stage'")
      tmux set -p -t "$stage_pane" @is_pi_stage 1
    else
      tmux display-popup -E -w 80% -h 70% -T " pi prompt (staging) " \
        "$editor '$stage'"
    fi
    bytes=$(wc -c < "$stage" 2>/dev/null || echo 0)
    tmux display-message "pi prompt: $bytes bytes staged"
  '';

  # Sending the staged content is handled by the pi /stage extension,
  # which calls pasteToEditor directly and avoids tmux's csi-u re-encoding
  # of LF inside bracketed paste.
  piPromptDiscard = pkgs.writeShellScript "tmux-pi-prompt-discard" ''
    set -e
    stage=${piStagePath}
    : > "$stage" 2>/dev/null || true
    tmux display-message "pi prompt: cleared"
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

  showTerm = pkgs.writeShellScript "tmux-showterm" ''
    # Multi-slot bottom-term dock (1-9). Pressing a slot shows it and
    # auto-hides whichever slot is currently visible. Pressing the
    # same slot twice toggles it off.
    #
    # Tag scheme:
    #   @__term_slot_N  — slot-N pane, visible in current window
    set -e

    SLOTS=9
    case "''${1}" in
      hide) TARGET=0 ;;
      *) TARGET="''${1:-1}" ; if [ "$TARGET" -lt 1 ] || [ "$TARGET" -gt $SLOTS ]; then
          tmux display-message "term dock: slot 1-$SLOTS"; exit 1
        fi ;;
    esac

    cur_win=$(tmux display -p '#{window_id}')
    PANE_SIZE="30%"

    # find currently visible term slot (any) in this window
    vis_pane="" vis_slot=0
    for n in $(seq 1 $SLOTS); do
      hit=$(tmux list-panes -s -F "#{pane_id} #{window_id} #{@__term_slot_$n}" | awk -v w="$cur_win" '$2==w && $3==1 {print $1; exit}')
      if [ -n "$hit" ]; then vis_pane="$hit"; vis_slot=$n; break; fi
    done

    if [ "$TARGET" -ne 0 ]; then
      # find target: visible first, then hidden bg
      target_pane="" was_hidden=0
      if [ -n "$vis_pane" ] && [ "$vis_slot" -eq $TARGET ]; then
        target_pane="$vis_pane"
      fi
      if [ -z "$target_pane" ]; then
        # find hidden bg window by name, then its pane
        bg_win=$(tmux list-windows -F '#{window_id} #{window_name}' | awk -v nm="[term-$TARGET]" '$2==nm {print $1}')
        if [ -n "$bg_win" ]; then
          target_pane=$(tmux list-panes -t "$bg_win" -F '#{pane_id}')
          was_hidden=1
        fi
      fi

      # same as already-visible → toggle off
      if [ -n "$vis_pane" ] && [ "$vis_slot" -eq $TARGET ]; then
        tmux break-pane -d -n "[term-$TARGET]" -s "$vis_pane"
        tmux set -p -t "$vis_pane" @__term_slot_$TARGET ""
        tmux set -p -t "$vis_pane" @__term_label ""
        exit 0
      fi

      # hide previous visible slot FIRST to avoid transient 3-pane layout
      if [ -n "$vis_pane" ]; then
        tmux break-pane -d -n "[term-$vis_slot]" -s "$vis_pane"
        tmux set -p -t "$vis_pane" @__term_slot_$vis_slot ""
        tmux set -p -t "$vis_pane" @__term_label ""
        vis_pane=""
      fi

      anchor=$(tmux list-panes -F '#{pane_id} #{@pane-is-vim}' | awk '$2==1 {print $1; exit}')
      [ -n "$anchor" ] && anchor_arg="-t $anchor" || anchor_arg=""

      # show target
      if [ -n "$target_pane" ] && [ "$was_hidden" -eq 1 ]; then
        tmux join-pane -v -l $PANE_SIZE $anchor_arg -s "$target_pane"
      fi

      # brand-new pane
      if [ -z "$target_pane" ]; then
        target_pane=$(tmux split-window -v -l $PANE_SIZE $anchor_arg -P -F '#{pane_id}' -c "#{pane_current_path}")
      fi

      tmux set -p -t "$target_pane" @__term_slot_$TARGET 1
      tmux set -p -t "$target_pane" @__term_label "term $TARGET"
      tmux select-pane -t "$target_pane"
    else
      for n in $(seq 1 $SLOTS); do
        hit=$(tmux list-panes -s -F "#{pane_id} #{@__term_slot_$n}" | awk '$2==1 {print $1; exit}')
        if [ -n "$hit" ]; then
          tmux break-pane -d -n "[term-$n]" -s "$hit"
          tmux set -p -t "$hit" @__term_slot_$n ""
          tmux set -p -t "$hit" @__term_label ""
        fi
      done

    fi
  '';

  # prefix b enters the term-dock table; then 1-9 selects a slot.
  termBinds = concatStringsSep "\n" (
    [ "bind b switch-client -T termdock" ]
    ++ map (n: "bind -T termdock ${toString n} run-shell '${showTerm} ${toString n}'") (lib.range 1 9)
  );

  lazygitToggle = mkToggle {
    name = "lazygit";
    tag = "is_lazygit";
    windowName = "[lazygit]";
    split = "-h";
    size = "100%";
    cmd = "lazygit";
    full = true;
  };

  seshPicker = pkgs.writeShellScript "tmux-sesh-picker" ''
    sel=$(sesh list --icons | fzf-tmux -p 80%,70% \
      --no-sort --ansi \
      --border-label ' sesh ' \
      --prompt '⚡  ' \
      --preview-window right:55% \
      --preview 'sesh preview {}' 2>/dev/null) || true
    [ -n "$sel" ] && sesh connect "$sel"
  '';

  defaultLayout = pkgs.writeShellScript "tmux-default-layout" ''
    set -e
    tmux rename-window edit
    tmux pi-toggle
    tmux select-pane -L
    tmux term-toggle
    tmux select-pane -U
  '';

  menu = import ./menu.nix {
    inherit
      pkgs
      seshPicker
      showTerm
      defaultLayout
      ;
  };
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
    concatMap (index: renderSection index (builtins.elemAt menu index)) (
      genList (index: index) (builtins.length menu)
    )
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
        bind-key -n C-h if-shell -F '#{@pane-is-vim}' 'send-keys C-h' 'if -F "#{pane_at_left}"   "" "select-pane -L"'
        bind-key -n C-j if-shell -F '#{@pane-is-vim}' 'send-keys C-j' 'if -F "#{pane_at_bottom}" "" "select-pane -D"'
        bind-key -n C-k if-shell -F '#{@pane-is-vim}' 'send-keys C-k' 'if -F "#{pane_at_top}"    "" "select-pane -U"'
        bind-key -n C-l if-shell -F '#{@pane-is-vim}' 'send-keys C-l' 'if -F "#{pane_at_right}"  "" "select-pane -R"'
        # In copy-mode, plain tmux navigation (no nvim forwarding needed)
        bind-key -T copy-mode-vi C-h if -F "#{pane_at_left}"   "" "select-pane -L"
        bind-key -T copy-mode-vi C-j if -F "#{pane_at_bottom}" "" "select-pane -D"
        bind-key -T copy-mode-vi C-k if -F "#{pane_at_top}"    "" "select-pane -U"
        bind-key -T copy-mode-vi C-l if -F "#{pane_at_right}"  "" "select-pane -R"

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
        # Inject text into the pi prompt without leaving copy-mode, so the
        # user can comment on output they're reading without scrolling down.
        # A: open $EDITOR in popup, paste result into pi pane on close.
        # Y: copy current selection and paste it into pi pane.
        # Staging-file workflow — A/Y accumulate, S flushes, X discards.
        bind-key -T copy-mode-vi A run-shell "${piPromptEdit}"
        bind-key -T copy-mode-vi X run-shell -b "${piPromptDiscard}"
        bind-key -T copy-mode-vi Escape send-keys -X cancel
        bind-key -T copy-mode-vi i send-keys -X cancel
        bind-key -T copy-mode-vi q send-keys -X cancel

        set -s command-alias[100] pi-toggle='run-shell ${piToggle}'
        set -s command-alias[101] term-toggle='run-shell "${showTerm} 1"'
        set -s command-alias[102] lazygit-toggle='run-shell ${lazygitToggle}'

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
        set -g pane-border-format " #{?@__term_label,#{@__term_label},#{?pane_title,#{pane_title},#{pane_current_command}}} "
        # Auto-rename pi/term toggle panes for clarity.
        set-hook -g after-split-window 'select-pane -T "#{pane_current_command}"'

        ${termBinds}

        run-shell ${pkgs.tmuxPlugins.mode-indicator}/share/tmux-plugins/mode-indicator/mode_indicator.tmux
      '';
    plugins = with pkgs.tmuxPlugins; [
      sensible
      extrakto
    ];
  };
}
