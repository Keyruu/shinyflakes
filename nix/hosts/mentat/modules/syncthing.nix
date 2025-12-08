{ config, ... }:
{
  sops.secrets.syncthingAdminPassword = { };

  services.syncthing = {
    dataDir = "/main/data/syncthing";
    guiAddress = "127.0.0.1:8384";
    guiPasswordFile = config.sops.secrets.syncthingAdminPassword.path;
    settings.gui = {
      user = "admin";
    };
  };

  services.nginx.virtualHosts."sync-mentat.lab.keyruu.de" = {
    useACMEHost = "lab.keyruu.de";
    forceSSL = true;

    locations."/" = {
      proxyPass = "http://127.0.0.1:8384";
      proxyWebsockets = true;
    };
  };
}
