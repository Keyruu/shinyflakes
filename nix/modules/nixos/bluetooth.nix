{ pkgs, ... }:
{
  hardware = {
    bluetooth = {
      enable = true;
      powerOnBoot = true;
      package = pkgs.bluez5-experimental;
      settings.General = {
        Experimental = true;
        FastConnectable = true;
      };
    };
  };

  services.pipewire.wireplumber.extraConfig.bluetoothEnhancements = {
    "monitor.bluez.properties" = {
      # Enable dummy AVRCP player for proper media control support
      # This is required for AirPods and other devices to send play/pause/skip commands
      "bluez5.dummy-avrcp-player" = true;
    };
  };

  # remember the bluetooth device profile when reconnecting
  services.pulseaudio.extraConfig = ''
    load-module module-card-restore restore_bluetooth_profile=true
  '';
}
