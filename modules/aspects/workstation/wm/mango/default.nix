{ inputs, lib, ... }:
let
  # Mango only matches `name` against the connector (e.g. eDP-1,
  # DP-2), so description-based criteria (make/model) are skipped here —
  # kanshi owns the real layout anyway, this is just the startup default.
  # NOTE: mango warns against negative monitor coordinates with XWayland
  # (X11 click bugs); powder's docked positions are negative. Laptop-only
  # (eDP-1 at 0,0) is unaffected.
  mkMonitorRule =
    name: displays: monitors:
    let
      mon = monitors.${name};
      pos = lib.splitString "," (displays.positions.${name} or "0,0");
      x = builtins.elemAt pos 0;
      y = builtins.elemAt pos 1;
      raw = lib.removeSuffix "Hz" mon.mode;
      res = lib.splitString "@" raw;
      dims = lib.splitString "x" (builtins.elemAt res 0);
      w = builtins.elemAt dims 0;
      h = builtins.elemAt dims 1;
      refresh = if builtins.length res > 1 then builtins.elemAt res 1 else "60";
      isConnector = builtins.match "^(eDP|DP|HDMI|DVI|VGA|LVDS)-[0-9]+$" mon.criteria;
    in
    lib.optionalString (isConnector != null)
      "monitor_rule=name:^${mon.criteria}$,width:${w},height:${h},refresh:${refresh},x:${x},y:${y},scale:${toString mon.scale}";

  mkMonitorRules =
    displays: monitors:
    lib.concatMapStringsSep "\n" (n: mkMonitorRule n displays monitors) (
      displays.primary ++ displays.secondaries
    );
in
{
  den.aspects.workstation.wm.mango =
    { host, ... }:
    {
      nixos =
        {
          inputs',
          lib,
          ...
        }:
        {
          imports = [ inputs.mango.nixosModules.mango ];

          programs.mango = {
            enable = true;
            package = inputs'.mango.packages.mango;
          };

          services.greetd.settings = {
            default_session.command = lib.mkForce "${inputs'.mango.packages.mango}/bin/mango";
            initial_session.command = lib.mkForce "${inputs'.mango.packages.mango}/bin/mango";
          };

          # portal-wlr has no built-in output picker: without a chooser
          # every screencast request dies with "no output found". Vicinae's
          # dmenu mode fills in; store path because the portal service PATH
          # lacks the home profile.
          xdg.portal.wlr.settings.screencast = {
            chooser_type = "dmenu";
            chooser_cmd = "${inputs'.vicinae.packages.default}/bin/vicinae dmenu --format data";
          };
        };

      homeManager =
        {
          pkgs,
          inputs',
          config,
          user,
          lib,
          ...
        }:
        let
          t = user.theme;
          # "#4079d6" → "0x4079d6ff" (mango wants 0xRRGGBBAA)
          toArgb = c: "0x${lib.removePrefix "#" c}ff";
          # h/l focus columns in scroller but cycle tabs in monocle — mango
          # binds can't branch on layout, so decide via mmsg
          mango-focus = pkgs.writeShellScriptBin "mango-focus" ''
            mon=$(mmsg get focusing-client 2>/dev/null | ${pkgs.jq}/bin/jq -r '.monitor // empty')
            [ -z "$mon" ] && exit 0
            sym=$(mmsg get monitor "$mon" | ${pkgs.jq}/bin/jq -r '.layout_symbol')
            if [ "$sym" = "M" ]; then
              case "$1" in
                left) mmsg dispatch focusstack,prev ;;
                right) mmsg dispatch focusstack,next ;;
              esac
            else
              mmsg dispatch focusdir,"$1"
            fi
          '';
          mango-close = pkgs.writeShellScriptBin "mango-close" ''
            set -o pipefail
            dispatch=$(mmsg get focusing-client | ${pkgs.jq}/bin/jq -er '
              select(.id | type == "number") | select(.id > 0) |
              "\(if .is_scratchpad == true or .is_namedscratchpad == true
                then "minimized" else "killclient" end),client,\(.id)"
            ') || exit 0
            exec mmsg dispatch "$dispatch"
          '';
        in
        {
          imports = [ inputs.mango.hmModules.mango ];

          home.packages = [
            mango-focus
            mango-close
          ];

          # home.pointerCursor = {
          #   enable = true;
          #   package = pkgs.phinger-cursors;
          #   name = "phinger-cursors-light";
          #   size = 20;
          #   gtk.enable = true;
          # };

          wayland.windowManager.mango = {
            enable = true;
            package = inputs'.mango.packages.mango;

            extraConfig = # ini
              ''
                ${lib.optionalString (host.displays != null) (mkMonitorRules host.displays config.monitors)}

                repeat_rate=50
                repeat_delay=300
                sloppy_focus=1
                xkb_rules_layout=eu
                xkb_rules_options=caps:escape
                trackpad_click_method=2
                # Flat acceleration would multiply speed by
                # (1 + mouse_accel_speed) = 0 at -1.0, i.e. a dead cursor
                mouse_accel_profile=2
                mouse_accel_speed=-1.0

                border_px=3
                border_radius=7
                focus_color=${toArgb t.accent}
                # focused scratchpads use this instead of focus_color
                scratchpad_color=${toArgb t.accent}
                # move scratchpad to selected monitor on toggle and rescale
                # its size proportionally, keeping the 0.88 ratio per screen
                scratchpad_cross_monitor=1
                border_color=${toArgb t.border}
                shadows=1
                gap_inner_horizontal=4
                gap_inner_vertical=4
                gap_outer_horizontal=12
                gap_outer_vertical=0
                blur=1
                blur_layer=1
                # blur against real content behind windows, not cached wallpaper
                # (blur_optimized=0 — costs GPU)
                blur_optimized=0
                cursor_size=20
                cursor_theme=phinger-cursors-light

                # tab bar (scroller stacks) — defaults are Tokyo Night at 33px
                # with 4px borders; restyle from theme
                tab_bar_height=28
                tab_bar_decorate_fg_color=${toArgb t.muted}
                tab_bar_decorate_bg_color=${toArgb t.background}
                tab_bar_decorate_focus_fg_color=${toArgb t.onAccent}
                tab_bar_decorate_focus_bg_color=${toArgb t.accent}
                tab_bar_decorate_border_color=${toArgb t.border}
                tab_bar_decorate_border_width=1
                tab_bar_decorate_corner_radius=7
                tab_bar_decorate_padding_x=8
                tab_bar_decorate_padding_y=4
                tab_bar_decorate_font_desc=${t.font} 11

                tag_rule=id:*,layout_name:scroller
                scroller_default_proportion=1.0
                scroller_proportion_preset=0.333,0.5,0.666,1.0
                scroller_prefer_overspread=0
                scroller_prefer_center=1
                # partially off-screen scroller windows get pointer focus
                # (mango default; explicit for documentation)
                edge_scroller_pointer_focus=1
                # edge windows only take pointer focus when pointer moves
                # faster than this (px per motion event, ~125Hz mouse);
                # slow drift over edge windows no longer focuses them
                edge_scroller_focus_allow_speed=1.5

                # Short durations keep interactions snappier than 350-800ms defaults.
                animation_type_open=zoom
                animation_type_close=zoom
                tag_animation_direction=0
                animation_duration_move=200
                animation_duration_open=200
                animation_duration_tag=150
                animation_duration_close=150
                animation_curve_move=0.19,1,0.22,1
                animation_curve_tag=0.19,1,0.22,1
                animation_curve_open=0.19,1,0.22,1
                animation_curve_close=0.25,0.46,0.45,0.94

                exec_once=clipse -listen
                exec_once=1password --silent
                exec_once=handy

                # let apps steal focus on activation instead of just going
                # urgent (red border) — skips the xdg-activation token check
                window_rule=activation_bypass:1,app_id:^.*$
                window_rule=is_named_scratchpad:1,width:0.88,height:0.88,app_id:^com\.onepassword\.OnePassword$,title:^(?!Quick Access)
                window_rule=is_named_scratchpad:1,width:0.88,height:0.88,app_id:^sone$
                window_rule=is_named_scratchpad:1,width:0.88,height:0.88,app_id:^scratchpad$
                window_rule=is_floating:1,width:0.88,height:0.88,app_id:^vicinae-script$
                window_rule=is_floating:1,width:0.88,height:0.88,app_id:^vicinae-script-lg$
                window_rule=is_floating:1,width:0.6,height:0.5,app_id:^vicinae-script-md$
                window_rule=is_floating:1,width:0.4,height:0.3,app_id:^vicinae-script-sm$
                window_rule=is_floating:1,width:0.88,height:0.88,is_fullscreen:0,app_id:^com\.gabm\.satty$
                window_rule=is_fullscreen:1,app_id:^at\.yrlf\.wl_mirror$
                window_rule=is_floating:1,width:0.88,height:0.88,focused_opacity:0.96,unfocused_opacity:0.96,app_id:^obsidian$
                window_rule=is_floating:1,focused_opacity:0.85,unfocused_opacity:0.85,app_id:^glide-editor$
                window_rule=is_floating:1,width:0.6,height:0.5,app_id:^tridactyl-editor$

                # workspace routing: tags 1=browse 2=work 3=social 4=media
                window_rule=tags:1,app_id:^zen$
                window_rule=tags:1,app_id:^zen-beta$
                window_rule=tags:1,app_id:^qutebrowser
                window_rule=tags:2,app_id:^dev\.zed\.Zed$
                window_rule=tags:2,app_id:^org\.wezfurlong\.wezterm$
                window_rule=tags:2,app_id:^Alacritty$
                window_rule=tags:2,app_id:^kitty$
                window_rule=tags:4,width:0.5,app_id:^spotify_player$
                window_rule=tags:4,width:0.5,app_id:^feishin$
                window_rule=tags:4,width:0.5,app_id:^spotify$
                window_rule=tags:4,width:0.5,title:^Picture-in-Picture$
                window_rule=tags:3,scroller_proportion:0.666,app_id:^Slack$
                window_rule=tags:3,scroller_proportion:0.666,app_id:^signal$
                window_rule=tags:3,scroller_proportion:0.666,app_id:^vesktop$
                window_rule=tags:3,scroller_proportion:0.666,app_id:^fluffychat$
                window_rule=tags:3,scroller_proportion:0.666,app_id:^Element$
                window_rule=tags:3,scroller_proportion:0.666,app_id:^cinny$
                window_rule=shield_when_capture:1,app_id:^com\.onepassword\.OnePassword$
                window_rule=shield_when_capture:1,app_id:^signal$
                window_rule=shield_when_capture:1,app_id:^vesktop$
                window_rule=shield_when_capture:1,app_id:^fluffychat$

                layer_rule=shield_when_capture:1,layer_name:^dms:dankisland$
                layer_rule=no_animation:1,no_blur:1,layer_name:selection

                bind=SUPER,Return,spawn,kitty
                bind=NONE,XF86AudioRaiseVolume,spawn,pamixer -i 5
                bind=NONE,XF86AudioLowerVolume,spawn,pamixer -d 5
                bind=NONE,XF86AudioMute,spawn,pamixer -t
                bind=NONE,XF86AudioPlay,spawn,playerctl play-pause
                # XF86AudioPause skipped: same keycode as XF86AudioPlay in xkb —
                # mango rejects the double bind, and both did play-pause anyway
                bind=NONE,XF86AudioStop,spawn,playerctl stop
                bind=NONE,XF86AudioNext,spawn,playerctl next
                bind=NONE,XF86AudioPrev,spawn,playerctl previous
                bind=NONE,XF86MonBrightnessUp,spawn,brightnessctl set +10%
                bind=NONE,XF86MonBrightnessDown,spawn,brightnessctl set 10%-

                bind=SUPER,h,spawn,mango-focus left
                bind=SUPER,j,focus_window_or_workspace,down
                bind=SUPER,k,focus_window_or_workspace,up
                bind=SUPER,l,spawn,mango-focus right
                bind=SUPER+SHIFT,h,move_client,left
                bind=SUPER+SHIFT,j,tagtoright
                bind=SUPER+SHIFT,k,tagtoleft
                bind=SUPER+SHIFT,l,move_client,right
                bind=CTRL+ALT,j,focusmon,down
                bind=CTRL+ALT,k,focusmon,up
                bind=CTRL+ALT,q,focusmon,next
                bind=CTRL+ALT+SHIFT,q,tagmon,next

                bind=SUPER,q,spawn,mango-close
                bind=SUPER,t,togglefloating
                bind=SUPER,f,togglemaximizescreen
                bind=SUPER+SHIFT,f,togglefullscreen
                bind=SUPER,comma,scroller_stack,right
                bind=SUPER,period,scroller_stack,left
                bind=SUPER,bracketright,focusstack,next
                bind=SUPER,bracketleft,focusstack,prev

                # plain bind since mango 6a73450: press and release both
                # swallowed — bindr would leak the press into the client
                bind=SUPER,space,spawn,vicinae toggle
                bind=ALT,space,toggle_named_scratchpad,scratchpad,none,kitty --class scratchpad
                bind=SUPER+SHIFT,space,spawn,1password --ozone-platform-hint=wayland --quick-access --enable-features=UseOzonePlatform,WebRTCPipeWireCapturer,WaylandWindowDecorations
                bind=SUPER+SHIFT,q,spawn,loginctl lock-session
                bind=SUPER+SHIFT,v,spawn,vicinae vicinae://launch/clipboard/history
                bind=SUPER,x,spawn_shell,wl-kbptr -c $HOME/.config/wl-kbptr/floating
                bind=SUPER,d,spawn,handy --toggle-transcription

                bind=NONE,Print,spawn,screenshot region
                bind=SHIFT,Print,spawn,screenshot screen
                bind=CTRL,Print,spawn,screenshot window
                bind=SUPER+SHIFT,4,spawn,screenshot region

                bind=SUPER,r,switch_proportion_preset
                bind=SUPER,m,spawn,wlr-which-key --initial-keys m p
                bind=SUPER,g,spawn,wlr-which-key --initial-keys m
                bind=SUPER,w,spawn,wlr-which-key --initial-keys m w

                # Include all monitors and tags, not only the visible workspace.
                bind=ALT,Tab,switcher,all_next
                bind=ALT+SHIFT,Tab,switcher,all_prev
                bind=SUPER,Tab,switcher,all_next
                bind=SUPER+SHIFT,Tab,switcher,all_prev

                # Vertical swipes follow j/k workspace navigation despite tags
                # being a horizontal strip; horizontal swipes stay within columns.
                gesturebind=none,up,3,viewtoleft_have_client
                gesturebind=none,down,3,viewtoright_have_client
                gesturebind=none,left,3,spawn,mango-focus left
                gesturebind=none,right,3,spawn,mango-focus right
                gesturebind=none,up,4,enteroverview
                gesturebind=none,down,4,leaveoverview
                bind=NONE,XF86TouchpadToggle,toggle_trackpad_enable
              '';
          };
        };
    };
}
