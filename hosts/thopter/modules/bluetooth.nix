{ pkgs, ... }:
{
  hardware.enableAllFirmware = true;

  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
    input.General.UserspaceHID = true;
    settings = {
      General = {
        # Enable = "Source,Sink,Media,Socket";
        Experimental = true; # Optional: enables experimental features
        MaxConnections = 10;
      };
    };
  };

  environment.systemPackages = with pkgs; [
    bluez
    bluez-tools
    libinput
  ];

  # Enable Bluetooth GUI manager (optional but recommended)
  services.blueman.enable = true;
}
