# Pure data: which-key menu definition. The main tmux module imports this and
# derives both the `display-menu` invocation and the `bind` lines from it.
#
# Shape:
#   <list>                  ordered list of categories
#   [i].title               section header text
#   [i].commands            ordered list of entries:
#     key      key the user presses inside the menu
#     label    text shown in the menu (padded for column alignment)
#     command  tmux command run when the entry is picked
#     hint     optional key-hint appended to the label as " (hint)"
#     bind     optional list — each element is either a string (prefix bind
#              for that key) or { flag?, key, repeat? } for full control.
#              Emits real `bind` lines so the action is reachable without
#              opening the menu.
{
  pkgs,
  seshPicker,
  showTerm,
  defaultLayout,
}:
[
  {
    title = "Windows";
    commands = [
      {
        key = "c";
        label = "New window";
        command = "new-window";
        hint = "c";
      }
      {
        key = "-";
        label = "Split horizontal";
        command = "split-window -v -c '#{pane_current_path}'";
        hint = "-";
        bind = [
          "-"
          ''"''
        ];
      }
      {
        key = "|";
        label = "Split vertical";
        command = "split-window -h -c '#{pane_current_path}'";
        hint = "|";
        bind = [
          "|"
          "%"
        ];
      }
      {
        key = "P";
        label = "Pi toggle";
        command = "pi-toggle";
        hint = "P";
        bind = [ "P" ];
      }
      {
        key = "T";
        label = "Bottom term toggle";
        command = "run-shell '${showTerm} 1'";
        hint = "b";
        bind = [ "T" ];
      }
      {
        key = "1";
        label = "Bottom term 1 toggle";
        command = "run-shell '${showTerm} 1'";
        hint = "b";
      }
      {
        key = "2";
        label = "Bottom term 2 toggle";
        command = "run-shell '${showTerm} 2'";
        hint = "b";
      }
      {
        key = "3";
        label = "Bottom term 3 toggle";
        command = "run-shell '${showTerm} 3'";
        hint = "b";
      }
      {
        key = "g";
        label = "Lazygit";
        command = "select-window -t git";
        hint = "g";
        bind = [
          "g"
          {
            flag = "-n";
            key = "C-g";
          }
        ];
      }
      {
        key = "e";
        label = "Extrakto picker";
        command = "run-shell -b '${pkgs.tmuxPlugins.extrakto}/share/tmux-plugins/extrakto/scripts/open.sh #{pane_id}'";
        hint = "e";
      }
      {
        key = "n";
        label = "Next window";
        command = "next-window";
        hint = "M-L";
      }
      {
        key = "p";
        label = "Previous window";
        command = "previous-window";
        hint = "M-H";
      }
      {
        key = "w";
        label = "Select window";
        command = "choose-tree";
      }
      {
        key = "r";
        label = "Rename window";
        command = "command-prompt -I '#W' 'rename-window %%'";
      }
      {
        key = "X";
        label = "Kill window";
        command = "confirm-before -p 'Kill window? (y/n)' kill-window";
      }
    ];
  }
  {
    title = "Panes";
    commands = [
      {
        key = "z";
        label = "Zoom toggle";
        command = "resize-pane -Z";
        hint = "z";
      }
      {
        key = "J";
        label = "Swap pane down";
        command = "swap-pane -D";
      }
      {
        key = "K";
        label = "Swap pane up";
        command = "swap-pane -U";
      }
      {
        key = "x";
        label = "Kill pane";
        command = "kill-pane";
        hint = "x";
        bind = [ "x" ];
      }
    ];
  }
  {
    title = "Sessions";
    commands = [
      {
        key = "s";
        label = "Session picker";
        command = "run-shell ${seshPicker}";
      }
      {
        key = "S";
        label = "New session";
        command = "command-prompt -p 'Session name:' 'new-session -s %%'";
      }
      {
        key = "R";
        label = "Rename session";
        command = "command-prompt -I '#S' 'rename-session %%'";
      }
      {
        key = "d";
        label = "Detach";
        command = "detach-client";
        hint = "d";
      }
    ];
  }
  {
    title = "Layout";
    commands = [
      {
        key = "D";
        label = "Dev layout";
        command = "run-shell '${defaultLayout}'";
      }
      {
        key = "L";
        label = "Next layout";
        command = "next-layout";
      }
      {
        key = "H";
        label = "Even horizontal";
        command = "select-layout even-horizontal";
      }
      {
        key = "V";
        label = "Even vertical";
        command = "select-layout even-vertical";
      }
    ];
  }
  {
    title = "Other";
    commands = [
      {
        key = "v";
        label = "Copy mode";
        command = "copy-mode";
        hint = "C-M-x";
      }
      {
        key = "C";
        label = "Reload config";
        command = "source-file ~/.config/tmux/tmux.conf; display 'Config reloaded'";
      }
      {
        key = ":";
        label = "Command prompt";
        command = "command-prompt";
        hint = ":";
      }
    ];
  }
]
