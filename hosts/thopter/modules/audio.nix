{ ... }:
{
  # Enable sound with pipewire.
  # hardware.pulseaudio = {
  #   enable = true;
  #   package = pkgs.pulseaudioFull;
  # };
  # services.pulseaudio.enable = true;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    # If you want to use JACK applications, uncomment this
    jack.enable = true;
    wireplumber = {
      enable = true;
      # extraConfig = {
      #   "10-bluez" = {
      #     "monitor.bluez.properties" = {
      #       "bluez5.enable-sbc-xq" = true;
      #       "bluez5.enable-msbc" = true;
      #       "bluez5.enable-hw-volume" = true;
      #       "bluez5.autoswitch-profile" = false;
      #       "bluez5.roles" = [
      #         "a2dp_sink"
      #         "a2dp_source"
      #         "hsp_hs"
      #         "hfp_hf"
      #         "hfp_ag"
      #       ];
      #     };
      #   };
      #   "11-bluetooth-policy" = {
      #     "wireplumber.settings" = {
      #       "bluetooth.autoswitch-to-headset-profile" = false;
      #     };
      #   };
      # };
    };

    # use the example session manager (no others are packaged yet so this is enabled by default,
    # no need to redefine it in your config for now)
    #media-session.enable = true;
  };
}
