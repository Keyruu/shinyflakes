{ lib, ... }:
{
  systemd.services = {
    nix-daemon.serviceConfig = {
      Nice = lib.mkForce 15;
      IOSchedulingClass = lib.mkForce "idle";
      IOSchedulingPriority = lib.mkForce 7;
    };

    nix-gc.serviceConfig = {
      Nice = lib.mkForce 15;
      IOSchedulingClass = lib.mkForce "idle";
      IOSchedulingPriority = lib.mkForce 7;
    };

    nix-optimise.serviceConfig = {
      Nice = lib.mkForce 15;
      IOSchedulingClass = lib.mkForce "idle";
      IOSchedulingPriority = lib.mkForce 7;
    };
  };
}
