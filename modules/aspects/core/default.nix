{ den, ... }: {
  den.aspects.core = {
    includes = with den.aspects.core; [
      common
      gc
      hardening
      locale
      nice
      nixConfig
      podman
      secrets
    ];
  };
}
