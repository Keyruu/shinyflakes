{
  services.kanata = {
    enable = true;
    keyboards = {
      homerow = {
        configFile = ./kanata-homerow.kbd;
        devices = [
          "/dev/input/by-path/platform-i8042-serio-0-event-kbd"
          "/dev/input/event0"
        ];
      };
    };
  };
}
