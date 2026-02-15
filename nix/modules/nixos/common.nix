{
  flake,
  pkgs,
  lib,
  inputs,
  config,
  ...
}:
{
  imports = [
    inputs.nix-topology.nixosModules.default

    ./settings.nix
  ];

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
      extraConfig = ''
        polkit.addRule(function(action, subject) {
          if (action.id == "org.freedesktop.systemd1.manage-units" &&
            subject.user == "${config.user.name}") {
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

    sudo = {
      execWheelOnly = true;
      extraConfig = ''
        Defaults lecture = never
        Defaults passwd_timeout=0
      '';
    };
  };

  sops.defaultSopsFile = ../../secrets.yaml;

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
      warn-dirty = false;

      # https://bmcgee.ie/posts/2023/12/til-how-to-optimise-substitutions-in-nix/
      max-substitution-jobs = 128;
      http-connections = 128;
      max-jobs = "auto";

      substituters = [
        "http://cache.keyruu.de:7384"
        "https://cache.nixos.org"
        "https://nix-community.cachix.org"
        "https://nixpkgs.cachix.org"
        "https://cache.lix.systems"
        "https://vicinae.cachix.org"
        "https://niri.cachix.org"
      ];
      trusted-public-keys = [
        "cache.keyruu.de:BifJnHe/XQhZmmFwLSZttthsXT4u2/L4aeo0k9zV+Kc="
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
        "nixpkgs.cachix.org-1:q91R6hxbwFvDqTSDKwDAV4T5PxqXGxswD8vhONFMeOE="
        "cache.lix.systems:aBnZUw8zA7H35Cz2RyKFVs3H4PlGTLawyY5KRbvJR8o="
        "vicinae.cachix.org-1:1kDrfienkGHPYbkpNj1mWTr7Fm1+zcenzgTizIcI3oc="
        "niri.cachix.org-1:Wv0OmO7PsuocRKzfDoJ3mulSl7Z6oezYhGhR+3W2964="
      ];
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
      trippy
    ];

    variables = {
      DO_NOT_TRACK = 1;
      EDITOR = "nvim";
    };
  };
}
