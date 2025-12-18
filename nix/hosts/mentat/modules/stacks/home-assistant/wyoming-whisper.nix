_:
let
  stackPath = "/etc/stacks/wyoming-whisper";
in
{
  systemd.tmpfiles.rules = [
    "d ${stackPath}/models 0755 root root"
    "d ${stackPath}/data 0755 root root"
  ];

  virtualisation.quadlet.containers = {
    wyoming-whisper = {
      containerConfig = {
        image = "slackr31337/wyoming-whisper-gpu:v2025.01.4";
        publishPorts = [ "127.0.0.1:10300:10300" ];
        environments = {
          MODEL = "medium";
          BEAM_SIZE = "0";
          LANGUAGE = "de";
          COMPUTE_TYPE = "int8";
        };
        devices = [ "nvidia.com/gpu=all" ];
        volumes = [
          "${stackPath}/models:/share/whisper"
          "${stackPath}/data:/data"
        ];
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
