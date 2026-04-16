_:
let
  stackPath = "/etc/stacks/isponsorblocktv";
in
{
  systemd.tmpfiles.rules = [
    "d ${stackPath}/data 0755 root root"
  ];

  virtualisation.quadlet.containers.isponsorblocktv = {
    containerConfig = {
      image = "ghcr.io/dmunozv04/isponsorblocktv:v2.7.0";
      networks = [
        "host"
      ];
      volumes = [
        "${stackPath}/data:/app/data"
      ];
    };
    serviceConfig = {
      Restart = "always";
    };
  };
}
