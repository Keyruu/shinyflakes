{...}: {
  programs.foot = {
    enable = true;
    settings = {
      main = {
        term = "foot";
        font-size-adjustment = "2.0";
        pad = "4x4 center";
      };
      key-bindings = {
        fullscreen = "F11";
      };
    };
  };
}
