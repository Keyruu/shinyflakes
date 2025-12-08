{
  pkgs,
  ...
}:
{
  environment.systemPackages = with pkgs; [
    brightnessctl
    mons
    acpi
  ];

  # use S3 sleep mode
  boot.kernelParams = [
    "mem_sleep_default=deep"
    "usbcore.autosuspend=120"
  ];

  # battery life improvements
  powerManagement = {
    enable = true;
    powertop.enable = true;
  };

  # turn off wifi without sudo
  security.sudo.extraRules = [
    {
      groups = [ "wheel" ];
      commands = [
        {
          command = "/run/current-system/sw/bin/rfkill";
          options = [ "NOPASSWD" ];
        }
      ];
    }
  ];

  services = {
    libinput.touchpad = {
      tapping = true;
      disableWhileTyping = false;
    };

    upower = {
      enable = true;
      percentageLow = 10;
      percentageCritical = 5;
      percentageAction = 2;
    };

    # Enable the auto-cpufreq daemon
    auto-cpufreq.enable = true;

    # Enable thermald, the temperature management daemon
    thermald.enable = true;

    tlp = {
      enable = true;
      settings = {
        DEVICES_TO_DISABLE_ON_STARTUP = "nfc";
      };
    };
  };
}
