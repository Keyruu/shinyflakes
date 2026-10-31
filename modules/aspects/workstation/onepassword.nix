{ ... }:
{
  den.aspects.workstation.onepassword = {
    nixos = { user, pkgs, ... }: {
      programs._1password.enable = true;
      programs._1password-gui = {
        enable = true;
        # NoDisplay: upstream desktop file only needs to stay registered as
        # the onepassword:// URI handler, not show up in launchers (the
        # Umbriel aspect ships the visible scratchpad entry)
        package = pkgs._1password-gui.overrideAttrs (old: {
          postInstall = (old.postInstall or "") + ''
            rm $out/share/applications/com.onepassword.OnePassword.desktop
          '';
        });
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

    # The desktop entry summons the Umbriel scratchpad; the compositor
    # starts 1Password on demand when it is empty.
    homeManager =
      {
        config,
        pkgs,
        lib,
        ...
      }:
      {
        xdg.desktopEntries."1password" = lib.mkIf config.programs.umbriel.enable {
          name = "1Password";
          exec = "${pkgs.writeShellScript "1password-scratchpad" ''
            exec ${config.programs.umbriel.package}/bin/umbriel msg scratchpad-toggle 1password
          ''}";
          icon = "1password";
          terminal = false;
          categories = [ "Utility" ];
        };
      };
  };
}
