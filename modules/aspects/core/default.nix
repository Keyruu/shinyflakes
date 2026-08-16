{ den, ... }: {
  den.aspects.core.default = {
    includes = with den.aspects.core; [
      common
      gc
      hardening
      locale
      nice
      nixConfig
      podman
    ];
  };
}
