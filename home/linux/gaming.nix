{ pkgs, ... }:
{
  home.packages = with pkgs; [
    prismlauncher # Minecraft launcher
    kdePackages.kdenlive # for editing obs clips
    mangohud
  ];

  # makes steam download a lot faster
  home.file.".steam/steam/steam_dev.cfg".text = ''
    @nClientDownloadEnableHTTP2PlatformLinux 0
    @fDownloadRateImprovementToAddAnotherConnection 1.0
  '';

  xdg.configFile."MangoHud/MangoHud.conf".text = ''
    toggle_fps_limit=F1
    toggle_hud=Shift_R+F12
    toggle_preset=Shift_R+F10

    legacy_layout=false
    background_alpha=0.3
    round_corners=8
    position=top-left
    font_size=20

    preset=1,2
  '';

  xdg.configFile."MangoHud/presets.conf".text = ''
    [preset 1]
    fps
    fps_only=1

    [preset 2]
    gpu_stats
    gpu_temp
    gpu_load_change
    cpu_stats
    cpu_temp
    cpu_load_change
    core_load_change
    vram
    ram
    fps
    show_fps_limit
    gamemode
    frame_timing=1
  '';

  programs.obs-studio = {
    enable = true;
    plugins = with pkgs.obs-studio-plugins; [
      obs-vaapi
      obs-vkcapture
      obs-websocket
    ];
  };
}
