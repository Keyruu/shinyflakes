{ pkgs, ... }:
{
  hardware.enableAllFirmware = true;
  boot.kernelPackages = pkgs.linuxPackages_latest;
  # boot.kernelParams = [ "thinkpad_acpi.disable_bluetooth=1" ];
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = false;
    package = pkgs.bluez5-experimental;

    settings = {
      # "bluez5.headset-roles" = {};
      Policy.ReconnectAttempts = 0;
      General = {
        ControllerMode = "bredr";
        # MultiProfile = "multiple";
        # Disable = "Headset";
        # Enable = "Source,Sink,Media,Socket";
        # Experimental = true;
        # FastConnectable = true;
        # KernelExperimental = "true";
      };
    };
  };

}
