{ config, pkgs, ... }:
{
  # nixpkgs.overlays = [ (import ./overlays/1password.nix) ];

  programs._1password.enable = true;
  programs._1password-gui = {
    enable = true;
    package = pkgs._1password-gui-beta;
    # Certain features, including CLI integration and system authentication support,
    # require enabling PolKit integration on some desktop environments (e.g. Plasma).
    polkitPolicyOwners = [ config.user.name ];
  };

  environment.etc = {
    "1password/custom_allowed_browsers" = {
      text = ''
        zen
        zen-bin
        .zen-wrapped
      '';
      mode = "0755";
    };
  };
}
