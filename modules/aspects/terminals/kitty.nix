{ ... }:
{
  den.aspects.terminals.kitty = {
    homeManager =
      {
        user,
        lib,
        pkgs,
        self',
        inputs',
        ...
      }:
      {
        xdg.configFile."xdg-terminals.list".text = ''
          kitty.desktop
        '';

        xdg.configFile."kitty/quick-access-terminal.conf".text = ''
          edge top
          layer overlay
          start_as_hidden yes
          kitty_override allow_remote_control=socket-only
        '';

        home.packages = [
          (pkgs.writeShellApplication {
            name = "kitty-quick-access";
            runtimeInputs = [
              pkgs.kitty
              pkgs.jq
              pkgs.coreutils
              pkgs.util-linux
              inputs'.niri.packages.niri-unstable
              self'.packages.zellij
            ];
            text = ''
              case "''${1:-}" in
                show) edge=top ;;
                toggle-edge) edge=center ;;
                *)
                  printf 'Usage: kitty-quick-access {show|toggle-edge}\n' >&2
                  exit 2
                  ;;
              esac

              # Serialize keypresses so concurrent launches cannot leave multiple Zellij clients.
              exec 9>"$XDG_RUNTIME_DIR/kitty-scratchpad.lock"
              flock 9

              # Resolve on every invocation so newly connected displays need no configuration.
              output=$(niri msg --json focused-output | jq -er '.name | select(type == "string" and length > 0)')
              socket="unix:$XDG_RUNTIME_DIR/kitty-scratchpad-$output"
              attached=false
              client_filter='any(.[] | .tabs[] | .windows[]; .user_vars.scratchpad_client == "1")'

              for panel in "$XDG_RUNTIME_DIR"/kitty-scratchpad-*; do
                [ -S "$panel" ] || continue
                panel="unix:$panel"
                if ! state=$(kitten @ --to "$panel" ls 2>/dev/null); then
                  continue
                fi
                if ! jq -e "$client_filter" <<< "$state" >/dev/null; then
                  continue
                fi
                if [ "$panel" = "$socket" ] && [ "$1" = toggle-edge ]; then
                  attached=true
                  if jq -e 'any(.[] | .tabs[] | .windows[]; .user_vars.quick_access_mode == "center")' <<< "$state" >/dev/null; then
                    edge=top
                  fi
                  continue
                fi

                # Only one scratchpad client is attached; detaching removes its overlay, not the panel.
                zellij --session scratchpad action detach
                deadline=$((SECONDS + 5))
                while kitten @ --to "$panel" ls 2>/dev/null | jq -e "$client_filter" >/dev/null; do
                  if (( SECONDS >= deadline )); then
                    printf 'Timed out detaching the scratchpad client\n' >&2
                    exit 1
                  fi
                  sleep 0.05
                done
                kitten @ --to "$panel" resize-os-window --match all --action=hide
                if [ "$panel" = "$socket" ] && [ "$1" = show ]; then
                  exit 0
                fi
              done

              if ! kitten @ --to "$socket" ls 2>/dev/null | jq -e '.[0].tabs[0].windows[0]' >/dev/null; then
                # Keep an idle base window alive when the Zellij overlay detaches.
                kitten quick-access-terminal --detach --instance-group "kitty-scratchpad-$$" \
                  --override "output_name=$output" --override "edge=$edge" --listen-on "$socket" \
                  sleep infinity 9>&-
                deadline=$((SECONDS + 5))
                until kitten @ --to "$socket" ls 2>/dev/null | jq -e '.[0].tabs[0].windows[0]' >/dev/null; do
                  if (( SECONDS >= deadline )); then
                    printf 'Timed out starting the scratchpad panel\n' >&2
                    exit 1
                  fi
                  sleep 0.05
                done
              fi

              # Ignore the bar's reserved space without changing it for other windows.
              kitten @ --to "$socket" resize-os-window --match all --action=os-panel --incremental "edge=$edge" exclusive-zone=-1 override-exclusive-zone=yes
              if [ "$attached" = false ]; then
                kitten @ --to "$socket" launch --type=overlay-main --var scratchpad_client=1 \
                  zellij attach --create scratchpad >/dev/null
              fi
              kitten @ --to "$socket" resize-os-window --match all --action=show
              kitten @ --to "$socket" set-user-vars --match all "quick_access_mode=$edge"
            '';
          })
        ];

        programs.kitty = {
          enable = true;

          shellIntegration = {
            enableFishIntegration = true;
            enableZshIntegration = true;
          };

          themeFile = "Dracula";

          settings = {
            window_margin_width = 0;
            window_padding_width = 10;
            window_border_width = "1px";
            hide_window_decorations = "titlebar-only";
            background_blur = "1";
            background_opacity = "0.9";
            enable_audio_bell = "false";
            visual_bell_duration = "0.2";
            visual_bell_color = "#003753";
            cursor_trail = 30;
            cursor_trail_decay = "0.1 0.4";
            cursor_trail_start_threshold = 10;
            custom_shaders = "cursor-trail-motion-blur cursor-splash find-pointer";
            font_family = user.theme.font;
            font_size = "13";
            scrollback_lines = "10000";
            scrollback_pager = lib.getExe self'.packages.nvim-scrollback;
          };

          keybindings = {
            "super+n" = "new_os_window_with_cwd";
            "ctrl+shift+space" = "show_scrollback";
            "f1" = "shader_event find-pointer";
          };

          # After theme so it overrides Dracula's #282a36 background
          extraConfig = ''
            background #100F0F
          '';
        };

        # Pipeline for the shader_event action, see docs/custom-shaders.rst
        home.file = {
          ".config/kitty/shaders/find-pointer.pipeline".text = ''
            startgroup
                animation_start user:find-pointer
                animation_stop 2000
                shaders spotlight
            endgroup
          '';

          # A splash at the position the cursor jumps to
          ".config/kitty/shaders/cursor-splash.pipeline".text = ''
            startgroup
                animation_start cursor-trail-move
                animation_stop 350
                animation_step 16
                shaders cursor-splash
            endgroup
          '';

          ".config/kitty/shaders/cursor-splash.slang".text = # slang
            ''
              #language slang 2026
              // A small splash that appears where the cursor jumps to, like a drop of water
              // hitting a surface. Meant to be used together with a cursor trail shader.

              import kitty_custom_shader_types;

              // Maximum radius of the splash, in UV units (of the window height).
              static const float SPLASH_RADIUS = 0.03;
              // Thickness of the expanding ring.
              static const float RING_WIDTH = 0.001;
              // Color of the splash, in linear RGB.
              static const float4 SPLASH_COLOR = float4(1.0, 1.0, 1.0, 1.0);
              // Only splash when the cursor moved at least this many cells.
              static const float MIN_DISTANCE_CELLS = 20.0;

              public float4
              fragment_main(float4 color, KittyTextures t, KittyCustomShaderData d) {
                  float progress = t.animation_progress;
                  if (progress <= 0.0 || progress >= 1.0) return color;

                  // The rectangle the cursor moved to: .x=left, .y=right, .z=top, .w=bottom
                  float4 edge = d.cursor_trail_history_to[0];
                  float4 prev = d.cursor_trail_history_from[0];
                  if (edge.y <= edge.x || prev.y <= prev.x) return color;
                  float2 center = float2((edge.x + edge.y) * 0.5, (edge.z + edge.w) * 0.5);

                  float2 pixel_dims = float2(d.viewport_size_pixels) * t.viewport.zw;
                  float aspect = pixel_dims.x / pixel_dims.y;

                  // Distance of the move in cells, to only splash on big jumps
                  float2 from_center = float2((prev.x + prev.y) * 0.5, (prev.z + prev.w) * 0.5);
                  float2 cell = float2((edge.y - edge.x) * aspect, edge.w - edge.z);
                  float2 moved = (center - from_center) * float2(aspect, 1.0) / cell;
                  if (length(moved) < MIN_DISTANCE_CELLS) return color;

                  float dist = length((t.pos - center) * float2(aspect, 1.0));
                  float radius = SPLASH_RADIUS * progress;
                  float ring = smoothstep(RING_WIDTH, RING_WIDTH * 0.25, abs(dist - radius));
                  float alpha = ring * (1.0 - progress) * SPLASH_COLOR.a;
                  if (alpha <= 0.0) return color;
                  return float4(lerp(color.rgb, SPLASH_COLOR.rgb, alpha), color.a);
              }
            '';
        };
      };
  };
}
