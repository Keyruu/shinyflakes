{ pkgs, inputs, ... }:
{
  systemd.services.sirberus = {
    description = "Sirberus systemd and container management";
    after = [ "network.target" ];
    wantedBy = [ "multi-user.target" ];

    serviceConfig = {
      ExecStart = "${inputs.sirberus.packages.${pkgs.stdenv.hostPlatform.system}.default}/bin/sirberus";
      Restart = "always";
      User = "0";
      RestartSec = 5;
      PrivilegedMode = true; # If you need full system access
    };
  };

  services.nginx.virtualHosts."sir-highwind.lab.keyruu.de" = {
    useACMEHost = "lab.keyruu.de";
    forceSSL = true;

    locations."/" = {
      proxyPass = "http://127.0.0.1:9733";
      proxyWebsockets = true;
    };
  };
}
