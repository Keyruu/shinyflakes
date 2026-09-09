{ ... }:
{
  den.aspects.workstation.sound = {
    nixos = { pkgs, ... }: {
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
                      "audio.format" = "S24_32LE";
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
                      "audio.format" = "S24_32LE";
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
      };

      security.rtkit.enable = true;

      environment.systemPackages = with pkgs; [
        playerctl
      ];
    };
  };
}
