{ ... }:
{
  den.aspects.workstation.wm.graphical = {
    nixos = { pkgs, ... }: {
      environment.systemPackages = with pkgs; [
        libnotify
        mesa
      ];

      # GTK3 schemas (e.g. org.gtk.Settings.FileChooser) needed for Qt apps using
      # the gtk3 platform theme — without this, file dialogs crash
      environment.sessionVariables.XDG_DATA_DIRS = [
        "${pkgs.gtk3}/share/gsettings-schemas/${pkgs.gtk3.name}"
      ];

      programs.dconf.enable = true;
      services.gnome.gnome-keyring.enable = true;
    };

    homeManager = { pkgs, ... }: {
      services.gnome-keyring.enable = true;
      services.polkit-gnome.enable = true;

      home.packages = with pkgs; [
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
