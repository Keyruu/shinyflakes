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
              - key: "n"
                desc: Niri
                submenu:
                  - key: "r"
                    desc: Resize
                    submenu:
                      - key: "h"
                        desc: Shrink Width
                        cmd: niri msg action set-column-width "-10%"
                        keep_open: true
                      - key: "j"
                        desc: Grow Height
                        cmd: niri msg action set-window-height "+10%"
                        keep_open: true
                      - key: "k"
                        desc: Shrink Height
                        cmd: niri msg action set-window-height "-10%"
                        keep_open: true
                      - key: "l"
                        desc: Grow Width
                        cmd: niri msg action set-column-width "+10%"
                        keep_open: true
                      - key: "Left"
                        desc: Shrink Width
                        cmd: niri msg action set-column-width "-10%"
                        keep_open: true
                      - key: "Down"
                        desc: Grow Height
                        cmd: niri msg action set-window-height "+10%"
                        keep_open: true
                      - key: "Up"
                        desc: Shrink Height
                        cmd: niri msg action set-window-height "-10%"
                        keep_open: true
                      - key: "Right"
                        desc: Grow Width
                        cmd: niri msg action set-column-width "+10%"
                        keep_open: true
                      - key: "f"
                        desc: Maximize Column
                        cmd: niri msg action maximize-column
                      - key: "e"
                        desc: Expand to Available
                        cmd: niri msg action expand-column-to-available-width
                      - key: "w"
                        desc: Switch Preset Width
                        cmd: niri msg action switch-preset-column-width
                      - key: "0"
                        desc: Reset Height
                        cmd: niri msg action reset-window-height
                  - key: "p"
                    desc: Programs
                    submenu:
                      - key: "t"
                        desc: Terminal
                        cmd: nirius focus-or-spawn -a foot footclient
                      - key: "b"
                        desc: Browser
                        cmd: nirius focus-or-spawn -a zen zen
                      - key: "z"
                        desc: Zed
                        cmd: nirius focus-or-spawn -a dev.zed.Zed zeditor
                      - key: "m"
                        desc: Music
                        cmd: nirius focus-or-spawn spotify
                      - key: "s"
                        desc: Slack
                        cmd: nirius focus-or-spawn -a Slack slack
                      - key: "o"
                        desc: Obsidian
                        cmd: scratch-niri obsidian obsidian
                      - key: "n"
                        desc: Notepad
                        cmd: dms ipc call notepad toggle
                  - key: "w"
                    desc: Workspaces
                    submenu:
                      - key: "b"
                        desc: Focus Browse
                        cmd: niri msg action focus-workspace browse
                      - key: "B"
                        desc: Move to Browse
                        cmd: niri msg action move-column-to-workspace browse
                      - key: "i"
                        desc: Focus IDE
                        cmd: niri msg action focus-workspace ide
                      - key: "I"
                        desc: Move to IDE
                        cmd: niri msg action move-column-to-workspace ide
                      - key: "t"
                        desc: Focus Terminal
                        cmd: niri msg action focus-workspace term
                      - key: "T"
                        desc: Move to Terminal
                        cmd: niri msg action move-column-to-workspace term
                      - key: "m"
                        desc: Focus Media
                        cmd: niri msg action focus-workspace media
                      - key: "M"
                        desc: Move to Media
                        cmd: niri msg action move-column-to-workspace media
                      - key: "s"
                        desc: Focus Social
                        cmd: niri msg action focus-workspace social
                      - key: "S"
                        desc: Move to Social
                        cmd: niri msg action move-column-to-workspace social
                  - key: "l"
                    desc: Layout
                    submenu:
                      - key: "f"
                        desc: Toggle Fullscreen
                        cmd: niri msg action toggle-fullscreen
                      - key: "t"
                        desc: Toggle Column Tabbed
                        cmd: niri msg action toggle-column-tabbed-display
                      - key: "c"
                        desc: Consume Window
                        cmd: niri msg action consume-window-into-column
                      - key: "e"
                        desc: Expel Window
                        cmd: niri msg action expel-window-from-column
                      - key: "s"
                        desc: Center Column
                        cmd: niri msg action center-column
                      - key: "w"
                        desc: Center Window
                        cmd: niri msg action center-window
                      - key: "v"
                        desc: Center All Visible
                        cmd: niri msg action center-visible-columns
                      - key: "m"
                        desc: Multi-Monitor
                        submenu:
                          - key: "h"
                            desc: Focus Monitor Left
                            cmd: niri msg action focus-monitor-left
                          - key: "j"
                            desc: Focus Monitor Down
                            cmd: niri msg action focus-monitor-down
                          - key: "k"
                            desc: Focus Monitor Up
                            cmd: niri msg action focus-monitor-up
                          - key: "l"
                            desc: Focus Monitor Right
                            cmd: niri msg action focus-monitor-right
                          - key: "Left"
                            desc: Focus Monitor Left
                            cmd: niri msg action focus-monitor-left
                          - key: "Down"
                            desc: Focus Monitor Down
                            cmd: niri msg action focus-monitor-down
                          - key: "Up"
                            desc: Focus Monitor Up
                            cmd: niri msg action focus-monitor-up
                          - key: "Right"
                            desc: Focus Monitor Right
                            cmd: niri msg action focus-monitor-right
                          - key: "H"
                            desc: Move to Monitor Left
                            cmd: niri msg action move-column-to-monitor-left
                          - key: "J"
                            desc: Move to Monitor Down
                            cmd: niri msg action move-column-to-monitor-down
                          - key: "K"
                            desc: Move to Monitor Up
                            cmd: niri msg action move-column-to-monitor-up
                          - key: "L"
                            desc: Move to Monitor Right
                            cmd: niri msg action move-column-to-monitor-right
                  - key: "f"
                    desc: Floating
                    submenu:
                      - key: "t"
                        desc: Toggle Floating
                        cmd: niri msg action toggle-window-floating
                      - key: "f"
                        desc: Move to Floating
                        cmd: niri msg action move-window-to-floating
                      - key: "i"
                        desc: Move to Tiling
                        cmd: niri msg action move-window-to-tiling
                      - key: "w"
                        desc: Focus Floating
                        cmd: niri msg action focus-floating
                      - key: "t"
                        desc: Focus Tiling
                        cmd: niri msg action focus-tiling
                      - key: "s"
                        desc: Switch Focus
                        cmd: niri msg action switch-focus-between-floating-and-tiling
                      - key: "m"
                        desc: Toggle Follow Mode
                        cmd: nirius toggle-follow-mode
                  - key: "o"
                    desc: Overview
                    cmd: niri msg action toggle-overview
                  - key: "h"
                    desc: Hotkey Overlay
                    cmd: niri msg action show-hotkey-overlay
                  - key: "d"
                    desc: Debug
                    submenu:
                      - key: "t"
                        desc: Toggle Tint
                        cmd: niri msg action toggle-debug-tint
                      - key: "o"
                        desc: Toggle Opaque Regions
                        cmd: niri msg action debug-toggle-opaque-regions
                      - key: "d"
                        desc: Toggle Damage
                        cmd: niri msg action debug-toggle-damage

              # mango menu — mirrors the niri entries above, but through mmsg
              # (mango IPC). Entries with no mango equivalent are omitted.
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
                      # vicinae launch deeplinks focus the app if running,
                      # spawn it otherwise — same behavior as nirius
                      # focus-or-spawn on niri
                      - key: "t"
                        desc: Terminal
                        cmd: vicinae vicinae://launch/applications/footclient
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
