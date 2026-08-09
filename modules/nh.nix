{ den, ... }: {
  perSystem = { pkgs, ... }: {
    packages = den.lib.nh.denPackages { fromFlake = true; } pkgs;
  };

  # Periodic `nh clean all`, keeping recent generations/results instead of
  # letting the store grow unbounded.
  den.default.nixos.programs.nh.clean = {
    enable = true;
    extraArgs = "--keep-since 7d --keep 5";
  };
}
