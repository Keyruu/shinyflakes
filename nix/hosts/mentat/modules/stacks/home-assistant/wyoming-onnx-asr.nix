{ config, ... }:
let
  stackPath = "/etc/stacks/wyoming-onnx-asr";
in
{
  systemd.tmpfiles.rules = [
    "d ${stackPath}/data 0755 root root"
  ];

  virtualisation.quadlet.containers = {
    wyoming-onnx-asr = {
      containerConfig = {
        image = "ghcr.io/tboby/wyoming-onnx-asr-gpu:v0.3.2";
        publishPorts = [ "127.0.0.1:10301:10300" ];
        devices = [ "nvidia.com/gpu=all" ];
        volumes = [
          "${stackPath}/data:/data"
        ];
        labels = [
          "wud.tag.include=^v\\d+\\.\\d+\\.\\d+$"
        ];
      };
      serviceConfig = {
        Restart = "always";
      };
    };
  };
}
