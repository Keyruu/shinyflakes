# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, inputs, ... }:
let
  fprintd-fix = import inputs.nixpkgs-fprintd-fix {
    system = pkgs.system;
    config.allowUnfree = true;
  };
in
{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
      inputs.nixos-hardware.nixosModules.lenovo-thinkpad-x1-yoga-7th-gen

      ./1password.nix
    ];

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "thopter"; # Define your hostname.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Enable networking
  networking.networkmanager.enable = true;

  # Set your time zone.
  time.timeZone = "Europe/Berlin";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "de_DE.UTF-8";
    LC_IDENTIFICATION = "de_DE.UTF-8";
    LC_MEASUREMENT = "de_DE.UTF-8";
    LC_MONETARY = "de_DE.UTF-8";
    LC_NAME = "de_DE.UTF-8";
    LC_NUMERIC = "de_DE.UTF-8";
    LC_PAPER = "de_DE.UTF-8";
    LC_TELEPHONE = "de_DE.UTF-8";
    LC_TIME = "de_DE.UTF-8";
  };

  # Enable the X11 windowing system.
  services.xserver = {
    enable = true;

    displayManager = {
      gdm = {
        enable = true;
	wayland = true;
      };
    };
    desktopManager.gnome.enable = false;
  };

  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };

  # Enable CUPS to print documents.
  services.printing.enable = true;

  # Enable sound with pipewire.
  # hardware.pulseaudio = {
  #   enable = true;
  #   package = pkgs.pulseaudioFull;
  # };
  # services.pulseaudio.enable = true;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    # If you want to use JACK applications, uncomment this
    jack.enable = true;
    wireplumber = {
      enable = true;
      # extraConfig = {
      #   "10-bluez" = {
      #     "monitor.bluez.properties" = {
      #       "bluez5.enable-sbc-xq" = true;
      #       "bluez5.enable-msbc" = true;
      #       "bluez5.enable-hw-volume" = true;
      #       "bluez5.autoswitch-profile" = false;
      #       "bluez5.roles" = [
      #         "a2dp_sink"
      #         "a2dp_source"
      #         "hsp_hs"
      #         "hfp_hf"
      #         "hfp_ag"
      #       ];
      #     };
      #   };
      #   "11-bluetooth-policy" = {
      #     "wireplumber.settings" = {
      #       "bluetooth.autoswitch-to-headset-profile" = false;
      #     };
      #   };
      # };
    };

    # use the example session manager (no others are packaged yet so this is enabled by default,
    # no need to redefine it in your config for now)
    #media-session.enable = true;
  };

  # Enable touchpad support (enabled default in most desktopManager).
  # services.xserver.libinput.enable = true;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.lucas = {
    isNormalUser = true;
    description = "Lucas";
    extraGroups = [ "networkmanager" "wheel" "ydotool" ];
    shell = pkgs.fish;
  };

  # Install firefox.
  programs.firefox.enable = true;
  programs.fish.enable = true;

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
    wget
    neovim
    lshw
    wezterm
    git
    kitty
    evtest
    wev
  ];

  services.fprintd.enable = true;

  services.fprintd.tod.enable = true;

  services.fprintd.package = fprintd-fix.fprintd;
  services.fprintd.tod.driver = fprintd-fix.libfprint-2-tod1-goodix;

  fonts.packages = with pkgs; [
    nerd-fonts.jetbrains-mono
  ];

  services.kanata = {
    enable = true;
    keyboards.lenovo.configFile = ../../home/common/kanata.kbd;
  };

  programs.hyprland.enable = true;

  services.upower.enable = true;
  services.blueman.enable = true;
  services.libinput.enable = true;
  services.power-profiles-daemon.enable = true;

  hardware.enableAllFirmware = true;
  boot.kernelPackages = pkgs.linuxPackages_latest;
  # boot.kernelParams = [ "thinkpad_acpi.disable_bluetooth=1" ];
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = false;
    package = pkgs.bluez5-experimental;

    settings = {
      # "bluez5.headset-roles" = {};
      Policy.ReconnectAttempts = 0;
      General = {
        ControllerMode = "bredr";
        # MultiProfile = "multiple";
        # Disable = "Headset";
        # Enable = "Source,Sink,Media,Socket";
        # Experimental = true;
        # FastConnectable = true;
        # KernelExperimental = "true";
      };
    };
  };

  services.tailscale.enable = true;

  programs.ydotool.enable = true;

  system.stateVersion = "24.11"; # Did you read the comment?
}
