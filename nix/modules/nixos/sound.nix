{ pkgs, ... }:
{
  services.pipewire = {
    enable = true;
    pulse.enable = true;

    # https://www.reddit.com/r/linux/comments/1em8biv/psa_pipewire_has_been_halving_your_battery_life/
    wireplumber = {
      enable = true;
      extraConfig = {
        "10-disable-camera.conf" = {
          "wireplumber.profiles".main."monitor.libcamera" = "disabled";
        };

        "51-device-rename.conf" = {
          "monitor.alsa.rules" = [
            {
              matches = [
                {
                  "node.name" = "alsa_output.pci-0000_00_1f.3-platform-skl_hda_dsp_generic.HiFi__Headphones__sink";
                }
              ];
              actions = {
                update-props = {
                  "node.description" = "Headphones";
                };
              };
            }
            {
              matches = [
                {
                  "node.name" = "alsa_output.pci-0000_00_1f.3-platform-skl_hda_dsp_generic.HiFi__Speaker__sink";
                }
              ];
              actions = {
                update-props = {
                  "node.description" = "Built-in Speaker";
                };
              };
            }
            {
              matches = [
                {
                  "node.name" = "alsa_input.pci-0000_00_1f.3-platform-skl_hda_dsp_generic.HiFi__Mic2__source";
                }
              ];
              actions = {
                update-props = {
                  "node.description" = "Built-in Microphone";
                };
              };
            }
            {
              matches = [
                {
                  "node.name" = "alsa_input.usb-Focusrite_Scarlett_Solo_USB_Y70FKBP2446854-00.HiFi__Mic1__source";
                }
              ];
              actions = {
                update-props = {
                  "node.description" = "Scarlett Solo Mic";
                };
              };
            }
          ];
        };
      };
    };

    extraConfig = {
      client."10-resample" = {
        "stream.properties" = {
          "resample.quality" = 10;
        };
      };

      # set higher pipewire quantum to fix issues with crackling sound
      pipewire."92-quantum" = {
        "context.properties" = {
          "default.clock.rate" = 48000;
          "default.clock.quantum" = 256;
          "default.clock.min-quantum" = 256;
          "default.clock.max-quantum" = 512;
        };
      };

      # also set the quantum for pipewire-pulse, this is often used by games
      pipewire-pulse."92-quantum" =
        let
          qr = "256/48000";
        in
        {
          "context.properties" = [
            {
              name = "libpipewire-module-protocol-pulse";
              args = { };
            }
          ];
          "pulse.properties" = {
            "pulse.default.req" = qr;
            "pulse.min.req" = qr;
            "pulse.max.req" = qr;
            "pulse.min.quantum" = qr;
            "pulse.max.quantum" = qr;
          };
          "stream.properties" = {
            "node.latency" = qr;
          };
        };
    };
  };

  security.rtkit.enable = true;

  environment.systemPackages = with pkgs; [
    playerctl
  ];
}
