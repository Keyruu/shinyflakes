{ den, ... }: {
  den.aspects.browsers = {
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
