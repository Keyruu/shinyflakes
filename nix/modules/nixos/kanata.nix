{
  services.kanata = {
    enable = true;
    keyboards = {
      homerow.configFile = ./kanata-config/kanata-homerow.kbd;
      common.configFile = ./kanata-config/kanata-common.kbd;
    };
  };
}
