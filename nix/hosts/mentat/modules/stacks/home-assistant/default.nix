{
  imports = [
    ./home-assistant.nix

    ./zigbee2mqtt.nix
    ./mqtt.nix
    ./matter-hub.nix
    ./esphome.nix
    ./music-assistant.nix
    # ./wyoming-whisper.nix
    # ./wyoming-piper.nix
    # ./wyoming-onnx-asr.nix
  ];
}
