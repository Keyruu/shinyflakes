{pkgs, ...}: {
  environment.systemPackages = with pkgs; [ mpv ];
  nixpkgs.overlays = [
    (self: super: {
      mpv = super.mpv.override {
        scripts = with self.mpvScripts; [
          mpv-osc-modern
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
        ];
      };
    })
  ];
}
