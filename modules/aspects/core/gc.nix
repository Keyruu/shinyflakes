{
  den.aspects.core.gc = {
    nixos = { ... }: {
      services.journald.settings.Journal.SystemMaxUse = "1G";

      # GC mid-build when free space drops below 3G, free up to 10G —
      # prime's 37G disk fills up during comin updates otherwise
      nix.settings = {
        min-free = 3 * 1024 * 1024 * 1024;
        max-free = 10 * 1024 * 1024 * 1024;
      };

      nix.optimise.automatic = true;
      nix.gc = {
        automatic = true;
        dates = "daily";
        options = "--delete-older-than 14d";
      };

      # Sometimes it fails if a store path is still in use.
      systemd.services.nix-gc.serviceConfig = {
        Restart = "on-failure";
      };
    };
  };
}