{ ... }:
{
  den.aspects.workstation.onepassword = {
    nixos = { user, ... }: {
      programs._1password.enable = true;
      programs._1password-gui = {
        enable = true;
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
            helium
            vivaldi
          '';
          mode = "0755";
        };
      };
    };
  };
}
