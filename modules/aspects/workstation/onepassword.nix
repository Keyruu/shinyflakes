{ ... }:
{
  den.aspects.workstation.onepassword = {
    nixos = { user, pkgs, ... }: {
      programs._1password.enable = true;
      programs._1password-gui = {
        enable = true;
        # NoDisplay: upstream desktop file only needs to stay registered as
        # the onepassword:// URI handler, not show up in launchers (the
        # mango aspect ships the visible scratchpad entry)
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

    # mango only: the entry summons the window as a named scratchpad (hidden
    # on open per the mango aspect's window rule); writeShellScript because
    # Exec forbids regex chars like $?() even when quoted
    homeManager =
      {
        config,
        pkgs,
        inputs',
        lib,
        ...
      }:
      {
        xdg.desktopEntries."1password" = lib.mkIf config.wayland.windowManager.mango.enable {
          name = "1Password";
          exec = "${pkgs.writeShellScript "1password-scratchpad" ''
            exec ${inputs'.mango.packages.mango}/bin/mmsg dispatch 'toggle_named_scratchpad,^com\.onepassword\.OnePassword$,^(?!Quick Access),1password'
          ''}";
          icon = "1password";
          terminal = false;
          categories = [ "Utility" ];
        };
      };
  };
}
