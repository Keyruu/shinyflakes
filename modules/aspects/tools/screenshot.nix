{ ... }:
{
  den.aspects.tools.screenshot = {
    homeManager =
      { pkgs, lib, inputs', ... }:
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
            inputs'.mango.packages.mango
          ];
          text = # bash
            ''
              mode=''${1:-region}

              case "$mode" in
                region)
                  capture=()
                  ;;
                screen)
                  monitor=$(mmsg get focusing-client | jq -r '.monitor // empty')
                  if [ -z "$monitor" ]; then
                    monitor=$(mmsg get cursorpos | jq -er '.monitor')
                  fi
                  capture=(-o "$monitor")
                  ;;
                window)
                  id=$(mmsg get focusing-client | jq -er '.foreign_toplevel_id // empty')
                  capture=(-T "$id")
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
