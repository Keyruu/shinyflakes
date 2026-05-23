{ pkgs, lib, ... }:
let
  tesseract = pkgs.tesseract.override {
    enableLanguages = [ "eng" "deu" ];
  };

  screenshot = pkgs.writeShellApplication {
    name = "screenshot";
    runtimeInputs = with pkgs; [
      grim
      slurp
      satty
      wl-clipboard
      libnotify
      jq
      niri
      coreutils
      tesseract
    ];
    text = # bash
      ''
        mode=''${1:-region}
        out_dir="''${XDG_PICTURES_DIR:-$HOME/Pictures}/Screenshots"
        mkdir -p "$out_dir"
        out="$out_dir/$(date +%Y-%m-%d_%H-%M-%S).png"

        run_satty() {
          satty --filename - --output-filename "$out"
        }

        case "$mode" in
          region)
            geom=$(slurp -d) || exit 0
            grim -g "$geom" - | run_satty
            ;;
          screen)
            output=$(niri msg -j focused-output | jq -r '.name')
            grim -o "$output" - | run_satty
            ;;
          all)
            grim - | run_satty
            ;;
          ocr)
            geom=$(slurp -d) || exit 0
            text=$(grim -g "$geom" - | tesseract -l eng+deu stdin stdout 2>/dev/null)
            if [ -z "$text" ]; then
              notify-send "OCR" "No text detected"
              exit 0
            fi
            printf '%s' "$text" | wl-copy
            notify-send "OCR" "Copied to clipboard:\n$text"
            ;;
          *)
            echo "usage: screenshot [region|screen|all|ocr]" >&2
            exit 2
            ;;
        esac
      '';
  };

  mkEntry = mode: label: {
    name = "Screenshot (${label})";
    exec = "${lib.getExe screenshot} ${mode}";
    terminal = false;
    type = "Application";
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
    screenshot-all = mkEntry "all" "All Screens";
    screenshot-ocr = mkEntry "ocr" "OCR Region";
  };
}
