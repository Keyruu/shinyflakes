{lib, ...}: {
  services.postgresql = {
    enable = true;
    authentication = lib.mkForce ''
      local all all trust
    '';
  };
}
