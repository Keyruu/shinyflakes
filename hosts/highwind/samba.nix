{ pkgs, ... }:
{
  # Bind mount /data/share into /srv/nfs
  fileSystems."/srv/samba" = {
    device = "/main";
    options = [ "bind" ];
  };

  users.users.lucas = {
    isNormalUser = true;
    uid = 1069;
  };

  services.samba = {
    enable = true;
    package = pkgs.sambaFull;
    openFirewall = true;
    settings = {
      global = {
        "workgroup" = "WORKGROUP";
        "security" = "user";
        "hosts allow" = "192.168.100. 100.64.0. 127.0.0.1 localhost";
        "hosts deny" = "0.0.0.0/0";
        "guest account" = "nobody";
        "map to guest" = "bad user";
      };
      "main" = {
        "path" = "/srv/samba";
        "browseable" = "yes";
        "read only" = "no";
        "guest ok" = "no";
        "create mask" = "0770";
        "directory mask" = "0770";
        "force user" = "root";
        "force group" = "root";
        "valid users" = [ "lucas" ];
      };
    };
  };

  services.samba-wsdd = {
    enable = true;
    discovery = true;
    openFirewall = true;
  };
}
