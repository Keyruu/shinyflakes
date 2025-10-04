{ pkgs, ... }:
{
  services.pipewire = {
    enable = true;
    pulse.enable = true;

    # https://www.reddit.com/r/linux/comments/1em8biv/psa_pipewire_has_been_halving_your_battery_life/
    wireplumber = {
      enable = true;
      extraConfig."10-disable-camera.conf" = {
        "wireplumber.profiles".main."monitor.libcamera" = "disabled";
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
