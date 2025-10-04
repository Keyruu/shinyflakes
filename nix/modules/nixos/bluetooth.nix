{ pkgs, ... }:
{
  hardware = {
    bluetooth = {
      enable = true;
      powerOnBoot = false;
      package = pkgs.bluez5-experimental;
      settings.General = {
        Experimental = true;
        FastConnectable = true;
      };
    };
  };

  # remember the bluetooth device profile when reconnecting
  services.pulseaudio.extraConfig = ''
    load-module module-card-restore restore_bluetooth_profile=true
  '';
}
