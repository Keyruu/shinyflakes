{
  services.kanata = {
    enable = true;
    keyboards = {
      homerow = {
        configFile = ./kanata-config/kanata-homerow.kbd;
        devices = [ "/dev/input/by-id/usb-ROYUAN_MonsGeek_Keyboard-event-kbd" ];
      };
      common = {
        configFile = ./kanata-config/kanata-common.kbd;
        devices = [ "/dev/input/by-id/usb-ZSA_Technology_Labs_Voyager_oyYzP_DzNPA7-event-kbd" ];
      };
    };
  };
}
