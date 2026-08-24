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
            helium
          '';
          mode = "0755";
        };
      };
    };

    homeManager = {
      xdg.desktopEntries."1password" = {
        name = "1Password";
        exec = "1password --ozone-platform-hint=wayland %U";
        terminal = false;
        type = "Application";
        icon = "1password";
        settings = {
          StartupWMClass = "1Password";
          Comment = "Password manager and secure wallet";
          MimeType = "x-scheme-handler/onepassword";
          Categories = "Office";
        };
      };
    };
  };
}
