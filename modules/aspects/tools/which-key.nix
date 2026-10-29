{ ... }:
{
  den.aspects.tools.which-key = {
    homeManager =
      {
        user,
        pkgs,
        lib,
        ...
      }:
      {
        home.packages = with pkgs; [
          wlr-which-key
        ];

        home.file.".config/wlr-which-key/config.yaml".text = # yaml
          ''
            # Theming
            font: ${user.theme.font} 12
            background: "${user.theme.background}d0"
            color: "${user.theme.foreground}"
            border: "${user.theme.accent}"
            separator: " ➜ "
            border_width: 2
            corner_r: 5
            padding: 15 # Defaults to corner_r
            # rows_per_column: 5 # No limit by default
            column_padding: 25 # Defaults to padding

            # Anchor and margin
            anchor: bottom-right # One of center, left, right, top, bottom, bottom-left, top-left, etc.
            # Only relevant when anchor is not center
            margin_right: 20
            margin_bottom: 20
            margin_left: 0
            margin_top: 0

            # Permits key bindings that conflict with compositor key bindings.
            # Default is `false`.
            inhibit_compositor_keyboard_shortcuts: true

            # Try to guess the correct keyboard layout to use. Default is `false`.
            auto_kbd_layout: true

            menu:
              - key: "m"
                desc: Mango
                submenu:
                  - key: "r"
                    desc: Resize
                    submenu:
                      - key: "h"
                        desc: Shrink Width
                        cmd: mmsg dispatch resizewin,-100,0
                        keep_open: true
                      - key: "j"
                        desc: Grow Height
                        cmd: mmsg dispatch resizewin,+0,+100
                        keep_open: true
                      - key: "k"
                        desc: Shrink Height
                        cmd: mmsg dispatch resizewin,+0,-100
                        keep_open: true
                      - key: "l"
                        desc: Grow Width
                        cmd: mmsg dispatch resizewin,+100,0
                        keep_open: true
                      - key: "Left"
                        desc: Shrink Width
                        cmd: mmsg dispatch resizewin,-100,0
                        keep_open: true
                      - key: "Down"
                        desc: Grow Height
                        cmd: mmsg dispatch resizewin,+0,+100
                        keep_open: true
                      - key: "Up"
                        desc: Shrink Height
                        cmd: mmsg dispatch resizewin,+0,-100
                        keep_open: true
                      - key: "Right"
                        desc: Grow Width
                        cmd: mmsg dispatch resizewin,+100,0
                        keep_open: true
                      - key: "f"
                        desc: Maximize Column
                        cmd: mmsg dispatch togglemaximizescreen
                      - key: "w"
                        desc: Switch Preset Width
                        cmd: mmsg dispatch switch_proportion_preset
                  - key: "p"
                    desc: Programs
                    submenu:
                      # Launch deeplinks reuse running apps instead of opening duplicates.
                      - key: "t"
                        desc: Terminal
                        cmd: vicinae vicinae://launch/applications/kitty
                      - key: "b"
                        desc: Browser
                        cmd: vicinae vicinae://launch/applications/zen
                      - key: "z"
                        desc: Zed
                        cmd: vicinae vicinae://launch/applications/dev.zed.Zed
                      - key: "m"
                        desc: Music
                        cmd: vicinae vicinae://launch/applications/spotify
                      - key: "s"
                        desc: Slack
                        cmd: vicinae vicinae://launch/applications/slack
                      - key: "o"
                        desc: Obsidian
                        cmd: vicinae vicinae://launch/applications/md.obsidian.Obsidian
                      - key: "n"
                        desc: Notepad
                        cmd: dms ipc call notepad toggle
                  - key: "w"
                    desc: Workspaces
                    submenu:
                      - key: "b"
                        desc: Focus Browse
                        cmd: mmsg dispatch view,1
                      - key: "B"
                        desc: Move to Browse
                        cmd: mmsg dispatch tag,1
                      - key: "i"
                        desc: Focus IDE
                        cmd: mmsg dispatch view,2
                      - key: "I"
                        desc: Move to IDE
                        cmd: mmsg dispatch tag,2
                      # mango merges terminals into the work tag (2)
                      - key: "t"
                        desc: Focus Terminal
                        cmd: mmsg dispatch view,2
                      - key: "T"
                        desc: Move to Terminal
                        cmd: mmsg dispatch tag,2
                      - key: "m"
                        desc: Focus Media
                        cmd: mmsg dispatch view,4
                      - key: "M"
                        desc: Move to Media
                        cmd: mmsg dispatch tag,4
                      - key: "s"
                        desc: Focus Social
                        cmd: mmsg dispatch view,3
                      - key: "S"
                        desc: Move to Social
                        cmd: mmsg dispatch tag,3
                  - key: "l"
                    desc: Layout
                    submenu:
                      - key: "f"
                        desc: Toggle Fullscreen
                        cmd: mmsg dispatch togglefullscreen
                      - key: "c"
                        desc: Consume Window
                        cmd: mmsg dispatch scroller_stack,right
                      - key: "e"
                        desc: Expel Window
                        cmd: mmsg dispatch scroller_stack,left
                      - key: "m"
                        desc: Multi-Monitor
                        submenu:
                          - key: "h"
                            desc: Focus Monitor Left
                            cmd: mmsg dispatch focusmon,left
                          - key: "j"
                            desc: Focus Monitor Down
                            cmd: mmsg dispatch focusmon,down
                          - key: "k"
                            desc: Focus Monitor Up
                            cmd: mmsg dispatch focusmon,up
                          - key: "l"
                            desc: Focus Monitor Right
                            cmd: mmsg dispatch focusmon,right
                          - key: "Left"
                            desc: Focus Monitor Left
                            cmd: mmsg dispatch focusmon,left
                          - key: "Down"
                            desc: Focus Monitor Down
                            cmd: mmsg dispatch focusmon,down
                          - key: "Up"
                            desc: Focus Monitor Up
                            cmd: mmsg dispatch focusmon,up
                          - key: "Right"
                            desc: Focus Monitor Right
                            cmd: mmsg dispatch focusmon,right
                          - key: "H"
                            desc: Move to Monitor Left
                            cmd: mmsg dispatch tagmon,left
                          - key: "J"
                            desc: Move to Monitor Down
                            cmd: mmsg dispatch tagmon,down
                          - key: "K"
                            desc: Move to Monitor Up
                            cmd: mmsg dispatch tagmon,up
                          - key: "L"
                            desc: Move to Monitor Right
                            cmd: mmsg dispatch tagmon,right
                  - key: "f"
                    desc: Floating
                    submenu:
                      - key: "t"
                        desc: Toggle Floating
                        cmd: mmsg dispatch togglefloating
                  - key: "o"
                    desc: Overview
                    cmd: mmsg dispatch toggleoverview
              - key: "p"
                desc: Power
                submenu:
                  - key: "s"
                    desc: Sleep
                    cmd: systemctl suspend
                  - key: "r"
                    desc: Reboot
                    cmd: reboot
                  - key: "o"
                    desc: Off
                    cmd: poweroff
          '';

        xdg.desktopEntries.which-key = {
          name = "wlr-which-key";
          exec = "${lib.getExe pkgs.wlr-which-key}";
          categories = [ "Utility" ];
          icon = "dialog-question";
        };
      };
  };
}
