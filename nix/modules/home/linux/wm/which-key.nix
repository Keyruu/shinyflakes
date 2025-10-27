{ pkgs, lib, ... }:
{
  home.packages = with pkgs; [
    wlr-which-key
  ];

  home.file.".config/wlr-which-key/config.yaml".text = # yaml
    ''
      # Theming
      font: JetBrainsMono Nerd Font 12
      background: "#202324d0"
      color: "#cdd6f4"
      border: "#003a6a"
      separator: " ➜ "
      border_width: 2
      corner_r: 0
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
            - key: "w"
              desc: Workspaces
              submenu:
                - key: "b"
                  desc: Focus Browse
                  cmd: niri msg action focus-workspace browse
                - key: "i"
                  desc: Focus IDE
                  cmd: niri msg action focus-workspace ide
                - key: "t"
                  desc: Focus Terminal
                  cmd: niri msg action focus-workspace term
                - key: "m"
                  desc: Focus Media
                  cmd: niri msg action focus-workspace media
                - key: "s"
                  desc: Focus Social
                  cmd: niri msg action focus-workspace social
            - key: "l"
              desc: Layout
              submenu:
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
        - key: "r"
          desc: Resize
          submenu:
            - key: "h"
              desc: Shrink Width
              cmd: swaymsg resize shrink width 10px
              keep_open: true
            - key: "j"
              desc: Grow Height
              cmd: swaymsg resize grow height 10px
              keep_open: true
            - key: "k"
              desc: Shrink Height
              cmd: swaymsg resize shrink height 10px
              keep_open: true
            - key: "l"
              desc: Grow Width
              cmd: swaymsg resize grow width 10px
              keep_open: true
            - key: "Left"
              desc: Shrink Width
              cmd: swaymsg resize shrink width 10px
              keep_open: true
            - key: "Down"
              desc: Grow Height
              cmd: swaymsg resize grow height 10px
              keep_open: true
            - key: "Up"
              desc: Shrink Height
              cmd: swaymsg resize shrink height 10px
              keep_open: true
            - key: "Right"
              desc: Grow Width
              cmd: swaymsg resize grow width 10px
              keep_open: true
            - key: "w"
              desc: Ultrawide Layout
              cmd: ultrawide
    '';

  xdg.desktopEntries.which-key = {
    name = "wlr-which-key";
    exec = "${lib.getExe pkgs.wlr-which-key}";
    terminal = false;
    type = "Application";
    categories = [ "Utility" ];
    icon = "dialog-question";
  };
}
