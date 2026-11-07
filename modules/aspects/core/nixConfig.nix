{ inputs, ... }:
{
  den.aspects.core.nixConfig = {
    nixos = { pkgs, lib, ... }: {
      imports = [ inputs.iets.nixosModules.default ];
      iets.classic = {
        enable = true;
        nix = pkgs.nixVersions.stable;
      };
      # Direnv and its iets hook are configured in Home Manager instead.
      iets.direnv.enable = false;

      nixpkgs.config.allowUnfree = true;
      # build-time pnpm deps flagged insecure in nixpkgs (vue-language-server, vesktop, ...)
      # FIXME: drop once https://github.com/NixOS/nixpkgs/issues/536623 lands in our pin
      nixpkgs.config.permittedInsecurePackages = [
        "pnpm-10.34.0"
        "pnpm-10.29.2"
      ];

      # revision of the flake the configuration was built from.
      # `nixos-version --configuration-revision` reads this. In blueprint,
      # `flake` was passed as a specialArg containing rev/dirtyRev. In den
      # there's no direct analog — set this per-host aspect or accept
      # "unknown" until the host aspect knows its source.
      # system.configurationRevision = "unknown";

      nix = {
        registry = lib.mapAttrs (_: fl: { flake = fl; }) inputs;
        nixPath = lib.mapAttrsToList (n: _: "${n}=flake:${n}") inputs;

        settings = {
          trusted-users = [
            "root"
            "@wheel"
          ];
          experimental-features = [
            "nix-command"
            "flakes"
          ];

          accept-flake-config = true;
          allow-import-from-derivation = true;
          builders-use-substitutes = true;
          keep-derivations = true;
          keep-outputs = true;
          warn-dirty = false;

          # https://bmcgee.ie/posts/2023/12/til-how-to-optimise-substitutions-in-nix/
          max-substitution-jobs = 128;
          http-connections = 128;
          max-jobs = "auto";

          substituters = [
            "https://cache.numtide.com"
            "https://vicinae.cachix.org"
            "https://niri-epireyn.cachix.org"
          ];
          trusted-public-keys = [
            "niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g="
            "vicinae.cachix.org-1:1kDrfienkGHPYbkpNj1mWTr7Fm1+zcenzgTizIcI3oc="
            "niri-epireyn.cachix.org-1:tlVyFN7CtsDT+ZcLPS+ekFWeT1X6X4OqvWqbBMyIzFA="
          ];
        };
        extraOptions = ''
          # Ensure we can still build when a binary cache is not accessible
          fallback = true
        '';
      };
    };
  };
}
