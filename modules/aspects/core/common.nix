{ ... }:
{
  den.aspects.core.common = {
    nixos =
      {
        user,
        pkgs,
        lib,
        config,
        ...
      }:
      {
        # disable beeping motherboard speaker
        boot = {
          blacklistedKernelModules = [ "pcspkr" ];

          kernelPackages = lib.mkDefault pkgs.linuxPackages_latest;

          # Tweaking the system's swap to take full advantage of zram.
          # https://wiki.archlinux.org/title/Zram#Optimizing_swap_on_zram
          kernel.sysctl = lib.mkIf config.zramSwap.enable {
            "vm.swappiness" = 180;
            "vm.watermark_boost_factor" = 0;
            "vm.watermark_scale_factor" = 125;
            "vm.page-cluster" = 0;
          };
        };

        zramSwap.enable = true;

        # make #!/bin/bash possible
        services.envfs.enable = true;

        hardware = {
          enableAllFirmware = true;
          enableRedistributableFirmware = true;
        };

        console = {
          earlySetup = true;
          font = "latarcyrheb-sun16";
        };

        security = {
          polkit = {
            enable = true;

            # allow me to use systemd without password every time
            # skipped when user is root — root already has full polkit access
            extraConfig = lib.mkIf (user.userName != "root") ''
              polkit.addRule(function(action, subject) {
                if (action.id == "org.freedesktop.systemd1.manage-units" &&
                  subject.user == "${user.userName}") {
                  return polkit.Result.YES;
                }
              });
              polkit.addRule(function(action, subject) {
                if (action.id == "com.1password.1Password.authorizeCLI") {
                  if (subject.isInGroup("users")) {
                    return polkit.Result.YES;
                  }
                }
              });
            '';
          };

          sudo.enable = false;
          sudo-rs = {
            enable = true;
            execWheelOnly = true;
            # extraConfig = ''
            #   Defaults lecture = never
            #   Defaults passwd_timeout=0
            # '';
          };
        };

        environment = {
          shells = [
            pkgs.bashInteractive
            pkgs.fish
          ];

          # uninstall all default packages that I don't need
          defaultPackages = lib.mkForce [ ];

          systemPackages = with pkgs; [
            git
            vim
            wget
            fastfetch
            pciutils
            usbutils
            dig
            trippy
            isd
          ];

          variables = {
            DO_NOT_TRACK = 1;
            EDITOR = "nvim";
          };
        };
      };
  };
}
