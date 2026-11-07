{ ... }:
{
  den.aspects.tools.screenshot = {
    homeManager =
      {
        pkgs,
        lib,
        inputs',
        ...
      }:
      let
        screenshot = pkgs.writeShellApplication {
          name = "screenshot";
          runtimeInputs = with pkgs; [
            grim
            slurp
            wl-clipboard
            libnotify
            jq
            satty
            coreutils
            llama-cpp
            inputs'.niri.packages.niri-unstable
          ];
          text = # bash
            ''
              mode=''${1:-region}

              case "$mode" in
                region|screen)
                  monitor=$(niri msg --json focused-output | jq -er '.name')
                  capture=(-o "$monitor")
                  ;;
                window)
                  output=$(niri msg --json focused-output)
                  geom=$(niri msg --json focused-window | jq -er --argjson output "$output" '
                    .layout as $layout |
                    $layout.tile_pos_in_workspace_view as $pos |
                    $layout.window_offset_in_tile as $offset |
                    $output.logical as $output |
                    "\((($output.x + $pos[0] + $offset[0]) | floor)),\((($output.y + $pos[1] + $offset[1]) | floor)) \($layout.window_size[0])x\($layout.window_size[1])"
                  ')
                  capture=(-g "$geom")
                  ;;
                ocr)
                  geom=$(slurp -d) || exit 0
                  img=$(mktemp --suffix=.png)
                  trap 'rm -f "$img"' EXIT
                  grim -g "$geom" "$img"
                  text=$(llama-mtmd-cli -hf ggml-org/GLM-OCR-GGUF:Q8_0 \
                    --image "$img" -p 'OCR this image. Output only the text.' \
                    -c 4096 --image-max-tokens 1024 \
                    2>/dev/null)
                  if [ -z "$text" ]; then
                    notify-send "OCR" "No text detected"
                    exit 0
                  fi
                  printf '%s' "$text" | wl-copy
                  notify-send "OCR" "Copied to clipboard:\n$text"
                  ;;
                *)
                  echo "usage: screenshot [region|screen|window|ocr]" >&2
                  exit 2
                  ;;
              esac

              dir="$HOME/Pictures/Screenshots"
              mkdir -p "$dir"
              img=$(mktemp --tmpdir="$dir" "Screenshot from $(date '+%Y-%m-%d %H-%M-%S').XXXXXX.png")
              if ! grim "''${capture[@]}" "$img"; then
                rm -f "$img"
                exit 1
              fi
              if [ "$mode" = region ]; then
                satty --filename "$img" --initial-tool crop --output-filename "$img" --save-after-copy
              else
                satty --filename "$img"
              fi
            '';
        };

        mkEntry = mode: label: {
          name = "Screenshot (${label})";
          exec = "${lib.getExe screenshot} ${mode}";
          categories = [
            "Utility"
            "Graphics"
          ];
          icon = "applets-screenshooter";
        };
      in
      {
        home.packages = [ screenshot ];

        xdg.desktopEntries = {
          screenshot-region = mkEntry "region" "Region";
          screenshot-screen = mkEntry "screen" "Focused Screen";
          screenshot-window = mkEntry "window" "Focused Window";
          screenshot-ocr = mkEntry "ocr" "OCR Region";
        };
      };
  };
}
