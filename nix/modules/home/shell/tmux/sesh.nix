{ pkgs, ... }:
let
  # Layout pi-toggle launches by default: nvim pane on the right, pi pane on
  # the left, term pane below nvim. Called from sesh's default_session hook.
  defaultLayout = pkgs.writeShellScript "sesh-default-layout" ''
    set -e
    tmux rename-window edit
    tmux pi-toggle
    tmux select-pane -L
    tmux term-toggle
    tmux select-pane -U
    exec vi
  '';
in
{
  programs.sesh = {
    enable = true;
    enableTmuxIntegration = false;
    settings = {
      default_session = {
        startup_command = "${defaultLayout}";
      };
      session = [
        {
          name = "shinyflakes";
          path = "~/shinyflakes";
        }
        {
          name = "git";
          path = "~/git";
          disable_startup_command = true;
        }
        {
          name = "home";
          path = "~";
          disable_startup_command = true;
        }
      ];
      wildcard = [
        { pattern = "~/git/*"; }
      ];
    };
  };
}
