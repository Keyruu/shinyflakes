{ den, ... }: {
  den.aspects.browsers.default = {
    includes = with den.aspects.browsers; [
      browser-picker
      chromium
      firefox
      tridactyl
    ];
  };
}
