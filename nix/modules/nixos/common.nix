{
  flake,
  pkgs,
  lib,
  inputs,
  config,
  ...
}:
{
  options.user.name = lib.mkOption {
    type = lib.types.str;
    description = "Primary user name";
  };

  config = {
    # disable beeping motherboard speaker
    boot.blacklistedKernelModules = [ "pcspkr" ];

    boot.kernelPackages = lib.mkDefault pkgs.linuxPackages_latest;

    zramSwap.enable = true;

    # Tweaking the system's swap to take full advantage of zram.
    # https://wiki.archlinux.org/title/Zram#Optimizing_swap_on_zram
    boot.kernel.sysctl = lib.mkIf config.zramSwap.enable {
      "vm.swappiness" = 180;
      "vm.watermark_boost_factor" = 0;
      "vm.watermark_scale_factor" = 125;
      "vm.page-cluster" = 0;
    };

    hardware = {
      enableAllFirmware = true;
      enableRedistributableFirmware = true;
    };

    console = {
      font = "ter-v24b";
      packages = [ pkgs.terminus_font ];
    };

    security = {
      polkit = {
        enable = true;

        # allow me to use systemd without password every time
        extraConfig = ''
          polkit.addRule(function(action, subject) {
            if (action.id == "org.freedesktop.systemd1.manage-units" &&
              subject.user == "${config.user.name}") {
              return polkit.Result.YES;
            }
          });
        '';
      };

      sudo = {
        execWheelOnly = true;
        extraConfig = ''
          Defaults lecture = never
          Defaults passwd_timeout=0
        '';
      };
    };

    nixpkgs.config.allowUnfree = true;

    # revision of the flake the configuration was built from.
    # $ nixos-version --configuration-revision
    system.configurationRevision = if (flake ? rev) then flake.rev else flake.dirtyRev;

    nix = {
      registry = lib.mapAttrs (_: flake: { inherit flake; }) inputs;
      nixPath = lib.mapAttrsToList (n: _: "${n}=flake:${n}") inputs;

      package = pkgs.nixVersions.latest;

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

        # https://bmcgee.ie/posts/2023/12/til-how-to-optimise-substitutions-in-nix/
        max-substitution-jobs = 128;
        http-connections = 128;
        max-jobs = "auto";
      };
      extraOptions = ''
        # Ensure we can still build when a binary cache is not accessible
        fallback = true
      '';
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
        neofetch
        pciutils
        usbutils
        dig
      ];

      variables = {
        DO_NOT_TRACK = 1;
      };
    };
  }; # close config block
}
