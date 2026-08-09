{ inputs, ... }:
{
  den.aspects.core.nixConfig = {
    nixos = { pkgs, lib, ... }: {
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

        package = pkgs.lixPackageSets.stable.lix;

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
            "https://cache.keyruu.de"
            "https://cache.nixos.org"
            "https://nix-community.cachix.org"
            "https://cache.numtide.com"
            "https://nixpkgs.cachix.org"
            "https://cache.lix.systems"
            "https://vicinae.cachix.org"
            "https://niri.cachix.org"
            "https://noctalia.cachix.org"
          ];
          trusted-public-keys = [
            "cache.keyruu.de:BifJnHe/XQhZmmFwLSZttthsXT4u2/L4aeo0k9zV+Kc="
            "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
            "nixpkgs.cachix.org-1:q91R6hxbwFvDqTSDKwDAV4T5PxqXGxswD8vhONFMeOE="
            "niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g="
            "cache.lix.systems:aBnZUw8zA7H35Cz2RyKFVs3H4PlGTLawyY5KRbvJR8o="
            "vicinae.cachix.org-1:1kDrfienkGHPYbkpNj1mWTr7Fm1+zcenzgTizIcI3oc="
            "niri.cachix.org-1:Wv0OmO7PsuocRKzfDoJ3mulSl7Z6oezYhGhR+3W2964="
            "noctalia.cachix.org-1:pCOR47nnMEo5thcxNDtzWpOxNFQsBRglJzxWPp3dkU4="
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
