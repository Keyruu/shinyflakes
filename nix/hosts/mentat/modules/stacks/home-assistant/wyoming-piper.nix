_:
let
  stackPath = "/etc/stacks/wyoming-piper";
in
{
  systemd.tmpfiles.rules = [
    "d ${stackPath}/data 0755 root root"
  ];

  virtualisation.quadlet.containers = {
    wyoming-piper = {
      containerConfig = {
        image = "slackr31337/wyoming-piper-gpu:v2025.08.0";
        publishPorts = [ "127.0.0.1:10200:10200" ];
        devices = [ "nvidia.com/gpu=all" ];
        volumes = [ "${stackPath}/data:/data" ];
        environments = {
          PIPER_VOICE = "de_DE-glados-high";
        };
        labels = [
          "wud.tag.include=^v\\d+\\.\\d+\\.\\d+$"
        ];
      };
      serviceConfig = {
        Restart = "unless-stopped";
      };
    };
  };
}
