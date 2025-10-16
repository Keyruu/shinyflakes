{
  services.kanata = {
    enable = true;
    keyboards = {
      lenovo.configFile = ./kanata-config/kanata-homerow.kbd;
      common.configFile = ./kanata-config/kanata-common.kbd;
    };
  };
}
