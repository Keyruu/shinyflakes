{ ... }:
{
  den.aspects.secrets = {
    nixos = { ... }: {
      # SOPS secrets file lives at repo root; the aspect lives at
      # modules/aspects/core/, so the relative path is three levels up.
      sops.defaultSopsFile = ../../../secrets.yaml;
    };
  };
}