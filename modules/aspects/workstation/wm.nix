{ ... }:
{
  den.aspects.workstation.wm = {
    homeManager =
      { pkgs, ... }:
      {
        services.gnome-keyring.enable = true;
        services.polkit-gnome.enable = true;

        home.packages = with pkgs; [
          wl-kbptr
          wl-clipboard
          brightnessctl
          grim
          slurp
          swappy
          imv
          wf-recorder
          wayland-utils
          wayland-protocols
          playerctl
          swaybg
          swayidle
          pamixer
          wlopm
          gcr
        ];
      };
  };
}
