{ pkgs, lib, ... }:
let
  focusOrSpawn =
    workspaceName: appId: command:
    if workspaceName != null then
      "nirius focus-or-spawn -a ${appId} ${command} && niri msg action focus-workspace ${workspaceName}"
    else
      "nirius focus-or-spawn -a ${appId} ${command}";

  workspaceBinds = lib.concatMapStrings (n: ''
    Alt+${toString n} hotkey-overlay-title=null { focus-workspace ${toString n}; }
    Alt+Shift+${toString n} hotkey-overlay-title=null { move-column-to-workspace ${toString n}; }
  '') (lib.range 1 9);
in
# kdl
''
  binds {
      // Media keys
      XF86AudioRaiseVolume hotkey-overlay-title=null { spawn "${pkgs.pamixer}/bin/pamixer" "-i" "5"; }
      XF86AudioLowerVolume hotkey-overlay-title=null { spawn "${pkgs.pamixer}/bin/pamixer" "-d" "5"; }
      XF86AudioMute hotkey-overlay-title=null { spawn "${pkgs.pamixer}/bin/pamixer" "-t"; }
      XF86AudioPlay hotkey-overlay-title=null { spawn "${pkgs.playerctl}/bin/playerctl" "play-pause"; }
      XF86AudioNext hotkey-overlay-title=null { spawn "${pkgs.playerctl}/bin/playerctl" "next"; }
      XF86AudioPrev hotkey-overlay-title=null { spawn "${pkgs.playerctl}/bin/playerctl" "previous"; }

      // Brightness
      XF86MonBrightnessUp hotkey-overlay-title=null { spawn "${pkgs.brightnessctl}/bin/brightnessctl" "set" "+10%"; }
      XF86MonBrightnessDown hotkey-overlay-title=null { spawn "${pkgs.brightnessctl}/bin/brightnessctl" "set" "10%-"; }

      // Application shortcuts
      Alt+E hotkey-overlay-title="Terminal" { spawn-sh "${
        focusOrSpawn "term" "Alacritty" "alacritty"
      }"; }
      Alt+C hotkey-overlay-title="Browser" { spawn-sh "${focusOrSpawn null "zen-beta" "zen"}"; }
      Alt+V hotkey-overlay-title="Code Editor" { spawn-sh "${
        focusOrSpawn "ide" "dev.zed.Zed" "zeditor"
      }"; }
      Alt+M hotkey-overlay-title="Music" { spawn-sh "${focusOrSpawn "media" "spotify" "spotify"}"; }
      Alt+A hotkey-overlay-title="Slack" { spawn-sh "${focusOrSpawn "social" "Slack" "slack"}"; }

      // Window management (vim-style)
      Alt+H hotkey-overlay-title="Focus Left" { focus-column-or-monitor-left; }
      Alt+J hotkey-overlay-title="Focus Down" { focus-window-or-workspace-down; }
      Alt+K hotkey-overlay-title="Focus Up" { focus-window-or-workspace-up; }
      Alt+L hotkey-overlay-title="Focus Right" { focus-column-or-monitor-right; }
      Alt+Shift+H hotkey-overlay-title="Move Window Left" { move-column-left; }
      Alt+Shift+J hotkey-overlay-title="Move Window Down" { move-window-down-or-to-workspace-down; }
      Alt+Shift+K hotkey-overlay-title="Move Window Up" { move-window-up-or-to-workspace-up; }
      Alt+Shift+L hotkey-overlay-title="Move Window Right" { move-column-right; }
      Ctrl+Alt+J hotkey-overlay-title="Focus Monitor Down" { focus-monitor-down; }
      Ctrl+Alt+K hotkey-overlay-title="Focus Monitor Up" { focus-monitor-up; }
      Alt+Q hotkey-overlay-title="Next Monitor" { focus-monitor-next; }
      Alt+Shift+Q hotkey-overlay-title="Move to Next Monitor" { move-window-to-monitor-next; }

      // Arrow key alternatives
      Alt+Left hotkey-overlay-title=null { focus-column-left; }
      Alt+Down hotkey-overlay-title=null { focus-window-down; }
      Alt+Up hotkey-overlay-title=null { focus-window-up; }
      Alt+Right hotkey-overlay-title=null { focus-column-right; }
      Alt+Shift+Left hotkey-overlay-title=null { move-column-left; }
      Alt+Shift+Down hotkey-overlay-title=null { move-window-down; }
      Alt+Shift+Up hotkey-overlay-title=null { move-window-up; }
      Alt+Shift+Right hotkey-overlay-title=null { move-column-right; }

      // Window actions
      Super+Q hotkey-overlay-title="Close Window" { close-window; }
      Alt+T hotkey-overlay-title="Toggle Floating" { toggle-window-floating; }
      Alt+F hotkey-overlay-title="Maximize Column" { maximize-column; }
      Alt+Shift+F hotkey-overlay-title="Fullscreen" { fullscreen-window; }
      Alt+Comma hotkey-overlay-title="Stack Window" { consume-window-into-column; }
      Alt+Period hotkey-overlay-title="Unstack Window" { expel-window-from-column; }

      // Launchers and utilities
      Super+Space hotkey-overlay-title="App Launcher" { spawn "vicinae" "toggle"; }
      Alt+Space hotkey-overlay-title="Scratchpad" { spawn "scratch-niri"; }
      Super+Shift+Space hotkey-overlay-title="1Password" { spawn "1password" "--ozone-platform-hint=wayland" "--quick-access" "--enable-features=UseOzonePlatform,WebRTCPipeWireCapturer,WaylandWindowDecorations"; }
      Super+Shift+L hotkey-overlay-title="Lock Screen" { spawn "noctalia-shell" "ipc" "call" "lockScreen" "lock"; }
      Super+Shift+V hotkey-overlay-title="Clipboard History" { spawn "vicinae" "vicinae://extensions/vicinae/clipboard/history"; }
      Super+X hotkey-overlay-title="Keyboard Pointer" { spawn "${pkgs.wl-kbptr}/bin/wl-kbptr" "-c" "$HOME/.config/wl-kbptr/floating"; }

      Super+Shift+4 hotkey-overlay-title="Screenshot" { screenshot; }

      // Copy/paste shortcuts
      Super+C hotkey-overlay-title=null { spawn "copyPasteShortcut" "copy" "org.wezfurlong.wezterm" "Alacritty" "dev.zed.Zed" "foot" "scratchpad"; }
      Super+V hotkey-overlay-title=null { spawn "copyPasteShortcut" "paste" "org.wezfurlong.wezterm" "Alacritty" "dev.zed.Zed" "foot" "scratchpad"; }
      Super+A hotkey-overlay-title=null { spawn "${pkgs.wtype}/bin/wtype" "-M" "ctrl" "-k" "a"; }
      Super+T hotkey-overlay-title=null { spawn "${pkgs.wtype}/bin/wtype" "-M" "ctrl" "-k" "t"; }
      Super+K hotkey-overlay-title=null { spawn "${pkgs.wtype}/bin/wtype" "-M" "ctrl" "-k" "k"; }
      Super+W hotkey-overlay-title=null { spawn "${pkgs.wtype}/bin/wtype" "-M" "ctrl" "-k" "w"; }
      Super+R hotkey-overlay-title=null { spawn "${pkgs.wtype}/bin/wtype" "-M" "ctrl" "-k" "r"; }
      Super+F hotkey-overlay-title=null { spawn "${pkgs.wtype}/bin/wtype" "-M" "ctrl" "-k" "f"; }

      // Resize and menus
      Alt+R hotkey-overlay-title="Cycle Column Width" { switch-preset-column-width; }
      Alt+G hotkey-overlay-title="Which Key Menu" { spawn "wlr-which-key" "--initial-keys" "n"; }
      Alt+W hotkey-overlay-title="Workspace Menu" { spawn "wlr-which-key" "--initial-keys" "n w"; }

      // Workspace switching and moving
      ${workspaceBinds}
    }
''
