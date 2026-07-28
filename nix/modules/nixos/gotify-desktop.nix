{ config, pkgs, ... }:
let
  user = config.user.name;
in
{
  sops.secrets.gotifyDesktopToken = { };

  sops.templates."gotify-desktop.toml" = {
    owner = user;
    file = (pkgs.formats.toml { }).generate "gotify-desktop.toml" {
      gotify = {
        url = "wss://notify.keyruu.de";
        token = config.sops.placeholder.gotifyDesktopToken;
        # shared client token across devices — deleting after read would starve others
        auto_delete = false;
      };
    };
  };

  systemd.tmpfiles.rules = [
    "d /home/${user}/.config/gotify-desktop 0755 ${user} users -"
    "L+ /home/${user}/.config/gotify-desktop/config.toml - - - - ${
      config.sops.templates."gotify-desktop.toml".path
    }"
  ];

  systemd.user.services.gotify-desktop = {
    description = "Gotify desktop notifications";
    after = [ "graphical-session.target" ];
    partOf = [ "graphical-session.target" ];
    wantedBy = [ "graphical-session.target" ];
    serviceConfig = {
      ExecStart = "${pkgs.gotify-desktop}/bin/gotify-desktop";
      Restart = "on-failure";
      RestartSec = 5;
    };
  };
}
