{ ... }:
{
  den.aspects.workstation.onepassword = {
    nixos = { user, pkgs, ... }: {
      programs._1password.enable = true;
      programs._1password-gui = {
        enable = true;
        package = pkgs._1password-gui;
        polkitPolicyOwners = [ user.userName ];
      };

      environment.etc = {
        "1password/custom_allowed_browsers" = {
          text = ''
            zen
            zen-bin
            .zen-wrapped
            librewolf
            glide-browser
            glide
            .glide-browser-wrapped
            .glide-wrapped
          '';
          mode = "0755";
        };
      };
    };
  };
}