{ lib, pkgs, ... }:
let
  # Emits current playing track via MPRIS, or a single space when nothing is
  # playing — hyprlock falls back to "Sample Text" on empty output.
  nowPlaying = pkgs.writeShellApplication {
    name = "hyprlock-now-playing";
    runtimeInputs = [ pkgs.playerctl ];
    text = ''
      if [ "$(playerctl status 2>/dev/null)" = Playing ]; then
        playerctl metadata --format '♪ {{artist}} — {{title}}' 2>/dev/null
      else
        echo ' '
      fi
    '';
  };
in
{
  # Display font for the giant clock. Rubik is a wide, rounded geometric sans;
  # the Black weight gives the chunky StretchPro-ish look. From nixpkgs.
  home.packages = [ pkgs.rubik ];

  programs.hyprlock = {
    enable = true;

    settings = {
      general = {
        no_fade_in = false;
        grace = 0;
        disable_loading_bar = false;
        hide_cursor = true;
        ignore_empty_input = true;
      };

      background = [
        {
          monitor = "";
          path = "${../themes/dark-bg.jpg}";
          blur_passes = 2;
          blur_size = 6;
          contrast = 0.8916;
          brightness = 0.8172;
          vibrancy = 0.1696;
          vibrancy_darkness = 0.0;
        }
      ];

      label = [
        # Time — hour
        {
          monitor = "";
          text = ''cmd[update:1000] echo "<span>$(${lib.getExe' pkgs.coreutils-full "date"} +"%H")</span>"'';
          color = "rgba(255, 255, 255, 1)";
          font_size = 175;
          font_family = "Rubik Black";
          position = "0, 280";
          halign = "center";
          valign = "center";
        }
        # Time — minute
        {
          monitor = "";
          text = ''cmd[update:1000] echo "<span>$(${lib.getExe' pkgs.coreutils-full "date"} +"%M")</span>"'';
          color = "rgba(70, 130, 220, 1)";
          font_size = 175;
          font_family = "Rubik Black";
          position = "0, 110";
          halign = "center";
          valign = "center";
        }
        # Day, Month, Date
        {
          monitor = "";
          text = ''cmd[update:1000] ${lib.getExe' pkgs.coreutils-full "date"} +"%d %B, %a."'';
          color = "rgba(180, 180, 180, 0.75)";
          font_size = 22;
          font_family = "Maple Mono Normal NL NF";
          position = "0, -8";
          halign = "center";
          valign = "center";
        }
        # Now playing (via playerctl, silent if no player)
        {
          monitor = "";
          # only render when a player is actively Playing, otherwise stay empty
          text = "cmd[update:2000] ${lib.getExe nowPlaying}";
          color = "rgba(147, 196, 255, 1)";
          font_size = 16;
          font_family = "Maple Mono Normal NL NF";
          position = "0, 40";
          halign = "center";
          valign = "bottom";
        }
        # Fingerprint prompt
        {
          monitor = "";
          text = "$FPRINTPROMPT";
          color = "rgba(216, 222, 233, 0.80)";
          font_size = 14;
          font_family = "DejaVu Sans";
          position = "0, -350";
          halign = "center";
          valign = "center";
        }
      ];

      input-field = [
        {
          monitor = "";
          size = "300, 60";
          outline_thickness = 2;
          dots_size = 0.2;
          dots_spacing = 0.2;
          dots_center = true;
          outer_color = "rgba(0, 0, 0, 0)";
          inner_color = "rgba(255, 255, 255, 0.1)";
          font_color = "rgb(200, 200, 200)";
          fade_on_empty = false;
          font_family = "DejaVu Sans";
          placeholder_text = ''<span foreground="##ffffff99">Enter Pass</span>'';
          hide_input = false;
          position = "0, -290";
          halign = "center";
          valign = "center";
        }
      ];
    };
  };
}
