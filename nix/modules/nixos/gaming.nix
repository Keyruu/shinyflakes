# yoinked from join
{
  pkgs,
  inputs,
  config,
  lib,
  ...
}:
let
  game-wrapper = pkgs.writeShellScriptBin "game-wrapper" ''
    # save LD_PRELOAD value.
    # It is set to empty for gamescope, but reset back to it's original value for the game process.
    # This fixes stuttering after 30 minutes of gameplay, but doesn't break steam overlay.
    LD_PRELOAD_SAVED="$LD_PRELOAD"
    export LD_PRELOAD=""

    exec gamemoderun \
      gamescope -r 144 -w 2560 -h 1440 -f -F pixel \
      --mangoapp \
      --force-grab-cursor \
      -- \
      env LD_PRELOAD=$LD_PRELOAD_SAVED \
      "$@"
  '';
in
{
  imports = [
    inputs.nix-gaming.nixosModules.platformOptimizations
  ];

  programs = {
    steam = {
      enable = true;
      platformOptimizations.enable = true;
      extraCompatPackages = [ pkgs.proton-ge-bin ];
      remotePlay.openFirewall = true;
      dedicatedServer.openFirewall = true;
      localNetworkGameTransfers.openFirewall = true;
    };

    gamemode = {
      enable = true;
      enableRenice = true;
      settings = {
        general = {
          reaper_freq = 5;
          desiredgov = "performance";
          renice = 10;
          ioprio = 0;
          inhibit_screensaver = 0;
          disable_splitlock = 1;
        };
        gpu = {
          apply_gpu_optimisations = "accept-responsibility";
          gpu_device = 1;
          amd_performance_level = "high";
        };
      };
    };

    gamescope.enable = true;

    # for minecraft
    java.enable = true;
  };

  users.users.${config.user.name}.extraGroups = [ "gamemode" ];

  hardware = {
    graphics = {
      enable = true;
      enable32Bit = true;

      # Add vulkan video encoding support
      extraPackages = with pkgs; [
        libva
      ];
    };

    # Xbox wireless controller driver
    xone.enable = true;
  };

  programs.gpu-screen-recorder.enable = true;

  environment.systemPackages =
    with pkgs;
    [
      vulkan-tools
      vulkan-loader
      vulkan-validation-layers
      vulkan-extension-layer
      protontricks
      winetricks
      protonplus
      libva-utils
      lutris-free
      (bottles.override { removeWarningPopup = true; })
      (wineWow64Packages.full.override {
        wineRelease = "staging";
        mingwSupport = true;
      })
      ludusavi
    ]
    ++ [
      game-wrapper
    ];
}
