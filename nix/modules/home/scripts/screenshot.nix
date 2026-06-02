{ pkgs, lib, ... }:
let
  tesseract = pkgs.tesseract.override {
    enableLanguages = [
      "eng"
      "deu"
    ];
  };

  watcher = pkgs.writeShellApplication {
    name = "niri-screenshot-watcher";
    runtimeInputs = with pkgs; [
      niri
      jq
      satty
    ];
    text = # bash
      ''
        exec niri msg --json event-stream \
          | jq --unbuffered -rn 'inputs | .ScreenshotCaptured?.path // empty' \
          | while IFS= read -r path; do
              [ -n "$path" ] || continue
              setsid -f satty --filename "$path" >/dev/null 2>&1 || true
            done
      '';
  };

  screenshot = pkgs.writeShellApplication {
    name = "screenshot";
    runtimeInputs = with pkgs; [
      grim
      slurp
      wl-clipboard
      libnotify
      niri
      coreutils
      tesseract
    ];
    text = # bash
      ''
        mode=''${1:-region}

        case "$mode" in
          region)
            niri msg action screenshot
            ;;
          screen)
            niri msg action screenshot-screen
            ;;
          window)
            niri msg action screenshot-window
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
            echo "usage: screenshot [region|screen|window|ocr]" >&2
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
  home.packages = [
    screenshot
    watcher
  ];

  xdg.desktopEntries = {
    screenshot-region = mkEntry "region" "Region";
    screenshot-screen = mkEntry "screen" "Focused Screen";
    screenshot-window = mkEntry "window" "Focused Window";
    screenshot-ocr = mkEntry "ocr" "OCR Region";
  };

  systemd.user.services.niri-screenshot-watcher = {
    Unit = {
      Description = "Pipe niri built-in screenshots to satty";
      PartOf = [ "graphical-session.target" ];
      After = [ "graphical-session.target" ];
    };
    Service = {
      ExecStart = "${lib.getExe watcher}";
      Restart = "on-failure";
      RestartSec = 2;
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };
}
