_:
let
  stackPath = "/etc/stacks/terraria";
in
{
  systemd.tmpfiles.rules = [
    "d ${stackPath}/config 0755 root root"
  ];

  virtualisation.quadlet.containers.terraria = {
    containerConfig = {
      image = "docker.io/passivelemon/terraria-docker:terraria-1.4.5";
      publishPorts = [ "7777:7777" ];
      volumes = [
        "${stackPath}/config:/opt/terraria/config/"
      ];
      environments = {
        WORLD = "wow";
      };
    };
    serviceConfig = {
      Restart = "always";
    };
  };
}
