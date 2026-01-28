_:
let
  stackPath = "/etc/stacks/terraria";
in
{
  systemd.tmpfiles.rules = [
    "d ${stackPath}/world 0755 root root"
  ];

  virtualisation.quadlet.containers.terraria = {
    containerConfig = {
      image = "docker.io/ryshe/terraria:latest";
      publishPorts = [ "7777:7777" ];
      volumes = [
        "${stackPath}/world:/root/.local/share/Terraria/Worlds"
      ];
      environments = {
        WORLD_FILENAME = "wow.wld";
      };
    };
    serviceConfig = {
      Restart = "always";
    };
  };
}
