{ pkgs, ... }:
{
  programs.mpv = {
    enable = true;
    config = {
      volume = 65;
      ytdl-format = "bestvideo+bestaudio/best";
      ytdl-raw-options = "sub-lang=en,write-subs=,embed-subs=,cookies-from-browser=firefox:$\{HOME}\/.zen/";
      slang = "en,eng";
      gpu-context = "wayland";
    };
    scripts = with pkgs.mpvScripts; [
      memo
      crop
      mpris
      seekTo
      reload
      encode
      cutter
      convert
      videoclip
      thumbfast
      chapterskip
      sponsorblock
      quality-menu
      eisa01.simplehistory
    ];
    bindings = {
      r = "cycle_values video-rotate 90 180 270 0";
    };
  };
}
