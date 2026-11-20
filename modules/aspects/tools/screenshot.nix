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
            wl-clipboard
            libnotify
            coreutils
            llama-cpp
            inputs'.dux-shell.packages.default
          ];
          text = # bash
            ''
              mode=''${1:-region}

              case "$mode" in
                region)
                  exec dms screenshot draw
                  ;;
                screen)
                  exec dms screenshot full
                  ;;
                window)
                  exec dms screenshot window
                  ;;
                ocr)
                  geom=$(dms screenshot region -g --no-file --no-clipboard --no-notify) || exit 0
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
