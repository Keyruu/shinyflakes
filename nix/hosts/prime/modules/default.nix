{
  imports = [
    ./stacks

    ./headscale.nix
    ./kanidm.nix
    ./caddy.nix
    # ./nginx.nix
    # ./niks3.nix
    ./postgres.nix
    ./proxy.nix
  ];
}
