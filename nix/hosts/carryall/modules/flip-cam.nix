{ config, pkgs, ... }:

{
  # Enable v4l2loopback kernel module
  boot.extraModulePackages = with config.boot.kernelPackages; [ v4l2loopback ];

  # Load module at boot with options
  boot.kernelModules = [ "v4l2loopback" ];
  boot.extraModprobeConfig = ''
    options v4l2loopback exclusive_caps=1 video_nr=10 card_label="Flipped Camera"
  '';

  # Install necessary packages
  environment.systemPackages = with pkgs; [
    v4l-utils
    ffmpeg
  ];

  # Optional: Create a systemd service to auto-start the flipped camera
  systemd.services.webcam-flip = {
    description = "Flipped Webcam Stream";
    wantedBy = [ "multi-user.target" ];
    after = [ "multi-user.target" ];

    serviceConfig = {
      Type = "simple";
      ExecStart = "${pkgs.ffmpeg}/bin/ffmpeg -f v4l2 -i /dev/video0 -vf hflip,format=yuv420p -f v4l2 /dev/video10";
      Restart = "always";
      RestartSec = "5";
      # Run as your user
      User = config.user.name; # Replace with your actual username
    };
  };
}
