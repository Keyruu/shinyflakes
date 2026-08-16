{ den, ... }: {
  den.aspects.browsers.default = {
    includes = with den.aspects.browsers; [
      chromium
      firefox
      glide
      sidebery
      vimium-c
      zen
    ];
  };
}
