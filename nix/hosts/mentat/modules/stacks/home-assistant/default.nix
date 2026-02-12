{
  imports = [
    ./home-assistant.nix

    ./zigbee2mqtt.nix
    ./mqtt.nix
    ./esphome.nix
    ./music-assistant.nix
    ./matter.nix
    ./openthread.nix
    # ./wyoming-whisper.nix
    # ./wyoming-piper.nix
    # ./wyoming-onnx-asr.nix
  ];
}
