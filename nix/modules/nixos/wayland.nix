{ lib, pkgs, ... }:
{
  security.pam.services = {
    hyprlock.fprintAuth = false; # use hyprlock's built in fprint implementation
  };

  services.xserver.enable = lib.mkForce false;

  xdg.portal = {
    enable = true;
    wlr.enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
    config = {
      common = {
        default = [
          "gtk"
        ];
      };
    };
  };

  # services.displayManager = {
  #   enable = true;
  #   ly.enable = true;
  # };
  services.greetd = {
    enable = true;

    settings = {
      default_session = {
        command = "${pkgs.tuigreet}/bin/tuigreet --time --cmd sway";
        user = "greeter";
      };
    };
  };
}
