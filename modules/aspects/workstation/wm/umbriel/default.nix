{ inputs, lib, ... }:
let
  # Kanshi owns hotplug layouts; this only supplies startup defaults.
  mkOutput =
    displays: monitors: name:
    let
      mon = monitors.${name};
      position = map lib.toInt (lib.splitString "," (displays.positions.${name} or "0,0"));
      connector = builtins.match "^(eDP|DP|HDMI|DVI|VGA|LVDS)-[0-9]+$" mon.criteria != null;
    in
    lib.optionalAttrs connector {
      ${mon.criteria} = {
        mode = lib.removeSuffix "Hz" mon.mode;
        inherit position;
        scale = mon.scale;
      };
    };

  rule = app_id: options: lib.recursiveUpdate { match = { inherit app_id; }; } options;
  sized =
    app_id: width: height:
    rule app_id {
      default_floating = true;
      default_floating_size = { inherit width height; };
    };
  routed = workspace: app_id: rule app_id { default_workspace = workspace; };
in
{
  den.aspects.workstation.wm.umbriel = { host, ... }: {
    nixos = { inputs', lib, ... }: {
      imports = [ inputs.umbriel.nixosModules.default ];
      programs.umbriel.enable = true;
      services.greetd.settings = {
        default_session.command = lib.mkForce "${inputs'.umbriel.packages.default}/bin/start-umbriel";
        initial_session.command = lib.mkForce "${inputs'.umbriel.packages.default}/bin/start-umbriel";
      };
    };

    homeManager =
      { config, user, ... }:
      let
        t = user.theme;
        rgba = c: "${c}FF";
      in
      {
        imports = [ inputs.umbriel.homeModules.default ];
        programs.umbriel = {
          enable = true;
          settings = {
            general = {
              autostart = [
                "clipse -listen"
                "1password --silent"
                "handy"
              ];
              focus_on_activate = true;
              show_cheatsheet = false;
            };
            output = lib.optionalAttrs (host.displays != null) (
              lib.mergeAttrsList (
                map (mkOutput host.displays config.monitors) (host.displays.primary ++ host.displays.secondaries)
              )
            );
            input = {
              keyboard = {
                layout = "eu";
                options = "caps:escape";
                repeat_rate = 50;
                repeat_delay = 300;
              };
              focus.follows_mouse = true;
              touchpad.tap_button_map = "left_middle_right";
              mouse = {
                accel_profile = "adaptive";
                sensitivity = -1.0;
              };
              cursor = {
                size = 20;
                theme = "phinger-cursors-light";
              };
            };
            appearance = {
              border_width = 3;
              corner_radius = 7;
              blur.optimized = false;
              shadow.enabled = true;
              tab_bar = {
                height = 28;
                font = "${t.font} 11";
                corner_radius = 7;
                padding = 8;
              };
            };
            colors = {
              border = {
                focused = rgba t.accent;
                unfocused = rgba t.border;
              };
              tab_bar = {
                background = rgba t.background;
                text = rgba t.muted;
                active = rgba t.accent;
                active_text = rgba t.onAccent;
              };
            };
            layout = {
              mode = "scrolling";
              gap = 4;
              extent_presets = [
                0.333
                0.5
                0.667
                1.0
              ];
              scrolling = {
                default_extent_fraction = 1.0;
                center_focused = "always";
              };
            };
            scratchpad = [
              {
                name = "scratchpad";
                spawn_when_empty = "kitty --class scratchpad";
              }
              {
                name = "1password";
                spawn_when_empty = "1password --silent";
              }
              {
                name = "sone";
                spawn_when_empty = "sone";
              }
            ];
            window_rule = [
              (rule "^com[.]onepassword[.]OnePassword$" {
                match.title = "^(?!Quick Access).+";
                default_scratchpad = "1password";
                default_floating_size = {
                  width = 0.88;
                  height = 0.88;
                };
                block_capture = true;
              })
              (rule "^sone$" {
                default_scratchpad = "sone";
                default_floating_size = {
                  width = 0.88;
                  height = 0.88;
                };
              })
              (rule "^scratchpad$" {
                default_scratchpad = "scratchpad";
                default_floating_size = {
                  width = 0.88;
                  height = 0.88;
                };
              })
              (sized "^vicinae-script(-lg)?$" 0.88 0.88)
              (sized "^vicinae-script-md$" 0.6 0.5)
              (sized "^vicinae-script-sm$" 0.4 0.3)
              (sized "^com[.]gabm[.]satty$" 0.88 0.88)
              (rule "^at[.]yrlf[.]wl_mirror$" { default_fullscreen = true; })
              ((sized "^obsidian$" 0.88 0.88) // { opacity = 0.96; })
              (rule "^glide-editor$" {
                default_floating = true;
                opacity = 0.85;
              })
              (sized "^tridactyl-editor$" 0.6 0.5)
              (routed 1 "^zen(-beta)?$")
              (routed 1 "^qutebrowser")
              (routed 2 "^dev[.]zed[.]Zed$")
              (routed 2 "^org[.]wezfurlong[.]wezterm$")
              (routed 2 "^Alacritty$")
              (routed 2 "^kitty$")
              ((routed 4 "^(spotify_player|feishin|spotify)$") // { default_scrolling_extent = 0.5; })
              {
                match.title = "^Picture-in-Picture$";
                default_workspace = 4;
                default_scrolling_extent = 0.5;
              }
              (
                (routed 3 "^(Slack|signal|vesktop|fluffychat|Element|cinny)$")
                // {
                  default_scrolling_extent = 0.667;
                }
              )
              (rule "^(signal|vesktop|fluffychat)$" { block_capture = true; })
            ];
            keybinds = {
              "Mod+Return" = "spawn kitty";
              "XF86AudioRaiseVolume" = "spawn pamixer -i 5";
              "XF86AudioLowerVolume" = "spawn pamixer -d 5";
              "XF86AudioMute" = "spawn pamixer -t";
              "XF86AudioPlay" = "spawn playerctl play-pause";
              "XF86AudioStop" = "spawn playerctl stop";
              "XF86AudioNext" = "spawn playerctl next";
              "XF86AudioPrev" = "spawn playerctl previous";
              "XF86MonBrightnessUp" = "spawn brightnessctl set +10%";
              "XF86MonBrightnessDown" = "spawn brightnessctl set 10%-";
              "Mod+H" = "window-focus-left";
              "Mod+J" = "window-focus-or-workspace-down";
              "Mod+K" = "window-focus-or-workspace-up";
              "Mod+L" = "window-focus-right";
              "Mod+Shift+H" = "window-move-left";
              "Mod+Shift+J" = "window-move-to-workspace-next";
              "Mod+Shift+K" = "window-move-to-workspace-previous";
              "Mod+Shift+L" = "window-move-right";
              "Ctrl+Alt+J" = "output-focus-down";
              "Ctrl+Alt+K" = "output-focus-up";
              "Ctrl+Alt+Q" = "output-focus-next";
              "Ctrl+Alt+Shift+Q" = "window-move-to-output-next";
              "Mod+Q" = "window-close";
              "Mod+T" = "window-toggle-floating";
              "Mod+F" = "window-toggle-maximize";
              "Mod+Shift+F" = "window-toggle-fullscreen";
              "Mod+Comma" = "window-consume-right";
              "Mod+Period" = "window-consume-or-expel-right";
              "Mod+BracketRight" = "column-focus-tab-next";
              "Mod+BracketLeft" = "column-focus-tab-previous";
              "Mod+Space" = {
                action = "spawn vicinae toggle";
                repeat = false;
              };
              "Alt+Space" = "scratchpad-toggle scratchpad";
              "Mod+Shift+Space" =
                "spawn 1password --ozone-platform-hint=wayland --quick-access --enable-features=UseOzonePlatform,WebRTCPipeWireCapturer,WaylandWindowDecorations";
              "Mod+Shift+Q" = "spawn loginctl lock-session";
              "Mod+Shift+V" = "spawn vicinae vicinae://launch/clipboard/history";
              "Mod+X" = "spawn wl-kbptr -c $HOME/.config/wl-kbptr/floating";
              "Mod+D" = "spawn handy --toggle-transcription";
              "Print" = "spawn screenshot region";
              "Shift+Print" = "spawn screenshot screen";
              "Ctrl+Print" = "spawn screenshot window";
              "Mod+Shift+4" = "spawn screenshot region";
              "Mod+R" = "window-cycle-primary-extent";
              "Mod+M" = "spawn wlr-which-key --initial-keys m p";
              "Mod+G" = "spawn wlr-which-key --initial-keys m";
              "Mod+W" = "spawn wlr-which-key --initial-keys m w";
              "Alt+Tab" = "window-focus-next";
              "Alt+Shift+Tab" = "window-focus-previous";
              "Mod+Tab" = "window-focus-next";
              "Mod+Shift+Tab" = "window-focus-previous";
            };
          };
        };
      };
  };
}
