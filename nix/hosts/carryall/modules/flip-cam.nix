{ config, pkgs, ... }:
{
  # 1. Enable ADB (Android Debug Bridge)
  programs.adb.enable = true;

  # 2. Install DroidCam and enable the virtual camera module
  environment.systemPackages = [ pkgs.droidcam ];

  # DroidCam needs a kernel module to create the video device
  boot.extraModulePackages = [ config.boot.kernelPackages.v4l2loopback ];
  boot.kernelModules = [ "v4l2loopback" ];

  # Optional: Label the DroidCam device so it's easy to find
  boot.extraModprobeConfig = ''
    options v4l2loopback exclusive_caps=1 video_nr=9 card_label="DroidCam"
  '';

  # 3. CRITICAL: Add your user to the 'adbusers' group
  # Replace 'yourusername' with your actual login name
  users.users.${config.user.name}.extraGroups = [
    "adbusers"
    "video"
  ];
}
