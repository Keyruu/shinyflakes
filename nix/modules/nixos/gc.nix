{
  services.journald.extraConfig = "SystemMaxUse=1G";

  nix.optimise.automatic = true;
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 14d";
  };

  # Sometimes it fails if a store path is still in use.
  systemd.services.nix-gc.serviceConfig = {
    Restart = "on-failure";
  };
}
