{ config, pkgs, ... }:
{
  programs._1password.enable = true;
  programs._1password-gui = {
    enable = true;
    package = pkgs._1password-gui;
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
