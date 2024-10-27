# Reusable modules
{
  brew = import ./brew.nix;
  darwin = import ./darwin.nix;
  docker = import ./docker.nix;
  hetzner = import ./hetzner;
  locale = import ./locale.nix;
  lvm-disk = import ./lvm-disk.nix;
  nginx = import ./nginx.nix;
  ssh-access = import ./ssh-access.nix;
  build-machines = import ./build-machines.nix;
  kanata = import ./kanata.nix;
}
