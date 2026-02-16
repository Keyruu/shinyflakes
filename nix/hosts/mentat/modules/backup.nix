{ config, ... }:
let
  repo = "/main/backup/restic";
in
{
  sops.secrets.resticHtpasswd = { };

  services.restic = {
    defaultRepo = repo;
    server = {
      enable = true;
      dataDir = "/main/backup";
      listenAddress = "8004";
      htpasswd-file = config.sops.secrets.resticHtpasswd.path;
    };
  };

  networking.firewall.extraCommands = "iptables -A INPUT -p tcp -s 100.67.0.1 --dport ${config.services.restic.server.listenAddress} -j ACCEPT";
}
