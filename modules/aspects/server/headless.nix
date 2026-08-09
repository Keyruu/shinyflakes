{ ... }:
{
  den.aspects.headless = {
    nixos = { pkgs, config, ... }: {
      # use bash for headless systems
      users.users.${config.user.name}.shell = pkgs.bashInteractive;
    };
  };
}