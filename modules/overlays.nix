{ inputs, ... }:
{
  perSystem = { system, ... }: {
    _module.args.pkgs = import inputs.nixpkgs {
      inherit system;
      overlays = [
        (final: prev: {
          zellij = inputs.zellij.packages.${system}.default;
          # The pinned nixpkgs khal passes a list to sphinxHook, which expects a string.
          khal = prev.khal.overrideAttrs (_: { sphinxBuilders = "html man"; });
        })
      ];
    };
  };
}
