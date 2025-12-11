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
      image = "ghcr.io/dmunozv04/isponsorblocktv:latest";
      networks = [
        "host"
      ];
      volumes = [
        "${stackPath}/data:/app/data"
      ];
      labels = [
        "wud.tag.include=^\\d+\\.\\d+\\.\\d+$"
      ];
    };
    serviceConfig = {
      Restart = "always";
    };
  };
}
