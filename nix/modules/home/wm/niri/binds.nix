{
  pkgs,
  lib,
  ...
}:
let
  workspaceBinds = lib.concatMapStrings (n: ''
    Alt+${toString n} hotkey-overlay-title=null { focus-workspace ${toString n}; }
    Alt+Shift+${toString n} hotkey-overlay-title=null { move-column-to-workspace ${toString n}; }
  '') (lib.range 1 9);
in
# kdl
''
  binds {
      XF86AudioRaiseVolume hotkey-overlay-title=null { spawn "${pkgs.pamixer}/bin/pamixer" "-i" "5"; }
      XF86AudioLowerVolume hotkey-overlay-title=null { spawn "${pkgs.pamixer}/bin/pamixer" "-d" "5"; }
      XF86AudioMute hotkey-overlay-title=null { spawn "${pkgs.pamixer}/bin/pamixer" "-t"; }
      XF86AudioPlay hotkey-overlay-title=null { spawn "${pkgs.playerctl}/bin/playerctl" "play-pause"; }
      XF86AudioNext hotkey-overlay-title=null { spawn "${pkgs.playerctl}/bin/playerctl" "next"; }
      XF86AudioPrev hotkey-overlay-title=null { spawn "${pkgs.playerctl}/bin/playerctl" "previous"; }

      XF86MonBrightnessUp hotkey-overlay-title=null { spawn "${pkgs.brightnessctl}/bin/brightnessctl" "set" "+10%"; }
      XF86MonBrightnessDown hotkey-overlay-title=null { spawn "${pkgs.brightnessctl}/bin/brightnessctl" "set" "10%-"; }

      Alt+H hotkey-overlay-title="Focus Left" { focus-column-left; }
      Alt+J hotkey-overlay-title="Focus Down" { focus-window-or-workspace-down; }
      Alt+K hotkey-overlay-title="Focus Up" { focus-window-or-workspace-up; }
      Alt+L hotkey-overlay-title="Focus Right" { focus-column-right; }
      Alt+Shift+H hotkey-overlay-title="Move Window Left" { move-column-left; }
      Alt+Shift+J hotkey-overlay-title="Move Window Down" { move-window-down-or-to-workspace-down; }
      Alt+Shift+K hotkey-overlay-title="Move Window Up" { move-window-up-or-to-workspace-up; }
      Alt+Shift+L hotkey-overlay-title="Move Window Right" { move-column-right; }
      Ctrl+Alt+J hotkey-overlay-title="Focus Monitor Down" { focus-monitor-down; }
      Ctrl+Alt+K hotkey-overlay-title="Focus Monitor Up" { focus-monitor-up; }
      Alt+Q hotkey-overlay-title="Next Monitor" { focus-monitor-next; }
      Alt+Shift+Q hotkey-overlay-title="Move to Next Monitor" { move-window-to-monitor-next; }

      Alt+Left hotkey-overlay-title=null { focus-column-left; }
      Alt+Down hotkey-overlay-title=null { focus-window-down; }
      Alt+Up hotkey-overlay-title=null { focus-window-up; }
      Alt+Right hotkey-overlay-title=null { focus-column-right; }
      Alt+Shift+Left hotkey-overlay-title=null { move-column-left; }
      Alt+Shift+Down hotkey-overlay-title=null { move-window-down; }
      Alt+Shift+Up hotkey-overlay-title=null { move-window-up; }
      Alt+Shift+Right hotkey-overlay-title=null { move-column-right; }

      Super+Q hotkey-overlay-title="Close Window" { close-window; }
      Alt+T hotkey-overlay-title="Toggle Floating" { toggle-window-floating; }
      Alt+F hotkey-overlay-title="Maximize Column" { maximize-column; }
      Alt+Shift+F hotkey-overlay-title="Fullscreen" { fullscreen-window; }
      Alt+Comma hotkey-overlay-title="Stack Window" { consume-window-into-column; }
      Alt+Period hotkey-overlay-title="Unstack Window" { expel-window-from-column; }

      Super+Space hotkey-overlay-title="App Launcher" { spawn "vicinae" "toggle"; }
      Alt+Space hotkey-overlay-title="Scratchpad" { spawn "scratch-niri" "scratchpad" "alacritty" "--class" "scratchpad"; }
      Super+Shift+Space hotkey-overlay-title="1Password" { spawn "1password" "--ozone-platform-hint=wayland" "--quick-access" "--enable-features=UseOzonePlatform,WebRTCPipeWireCapturer,WaylandWindowDecorations"; }
      Super+Shift+L hotkey-overlay-title="Lock Screen" { spawn "noctalia-ipc" "lockScreen" "lock"; }
      Super+Shift+V hotkey-overlay-title="Clipboard History" { spawn "vicinae" "vicinae://extensions/vicinae/clipboard/history"; }
      Super+X hotkey-overlay-title="Keyboard Pointer" { spawn-sh "${pkgs.wl-kbptr}/bin/wl-kbptr -c $HOME/.config/wl-kbptr/floating"; }

      Super+Shift+4 hotkey-overlay-title="Screenshot" { screenshot; }

      Alt+R hotkey-overlay-title="Cycle Column Width" { switch-preset-column-width; }
      Alt+M hotkey-overlay-title="Program Menu" { spawn "wlr-which-key" "--initial-keys" "n p"; }
      Alt+G hotkey-overlay-title="Which Key Menu" { spawn "wlr-which-key" "--initial-keys" "n"; }
      Alt+W hotkey-overlay-title="Workspace Menu" { spawn "wlr-which-key" "--initial-keys" "n w"; }

      ${workspaceBinds}
    }
''
