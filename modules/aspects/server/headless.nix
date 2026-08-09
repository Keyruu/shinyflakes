{ ... }:
{
  den.aspects.server.headless = {
    nixos = { user, pkgs, ... }: {
      # use bash for headless systems
      users.users.${user.userName}.shell = pkgs.bashInteractive;
    };
  };
}