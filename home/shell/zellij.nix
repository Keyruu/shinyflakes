{...}: {
  home.file.".config/zellij/layouts/nix.kdl".text =
    /*
    kdl
    */
    ''
      layout {
        pane size=1 borderless=true {
          plugin location="zellij:tab-bar"
        }
        pane split_direction="horizontal" {
          pane command="vi" size="70%" {
            args "."
            cwd "~/shinyflakes"
          }
          pane
        }
        pane size=2 borderless=true {
          plugin location="zellij:status-bar"
        }
      }
    '';

  programs.zellij = {
    enable = true;
  };
}
