{ ... }:
{
  den.aspects.terminals.kitty = {
    homeManager =
      {
        user,
        lib,
        self',
        ...
      }:
      {
        xdg.configFile."xdg-terminals.list".text = ''
          kitty.desktop
        '';

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
