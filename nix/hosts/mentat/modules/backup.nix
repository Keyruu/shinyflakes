{ config, ... }:
{
  users.groups.restic = { };
  users.users.restic = {
    isSystemUser = true;
    group = "restic";
  };
  sops = {
    secrets.resticHtpasswd = {
      owner = "restic";
      group = "restic";
    };
    templates."resticRepo".content =
      "rest:http://lucas:${config.sops.placeholder.resticServerPassword}@127.0.0.1:8004/restic";
  };

  services.restic = {
    defaultRepoFile = config.sops.templates."resticRepo".path;
    server = {
      enable = true;
      dataDir = "/main/backup";
      listenAddress = "8004";
      htpasswd-file = config.sops.secrets.resticHtpasswd.path;
    };
  };

  networking.firewall.extraCommands = "iptables -A INPUT -p tcp -s 100.67.0.1 --dport ${config.services.restic.server.listenAddress} -j ACCEPT";
}
