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

  services.greetd = {
    enable = true;
    settings = {
      default_session =
        let
          tuigreet =
            let
              theme = "--theme 'border=blue;text=lightblue;prompt=cyan;time=blue;action=cyan;button=white;container=darkblue;input=white;greet=lightcyan;title=lightblue'";
              time = "--time --time-format '%I:%M %p | %a • %h %d %Y'";
              greeting = "--greeting 'Guten Abend, Dubinski.'";
            in
            cmd: "${pkgs.tuigreet}/bin/tuigreet ${theme} ${time} --asterisks ${greeting} --cmd ${cmd}";
        in
        {
          command = tuigreet "sway"; # Replace with your default session
          user = "greeter";
        };
    };
  };

  security.pam.services.greetd.fprintAuth = false;
}
