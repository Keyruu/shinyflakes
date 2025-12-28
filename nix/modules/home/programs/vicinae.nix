{
  config,
  inputs,
  perSystem,
  ...
}:
{
  imports = [
    inputs.vicinae.homeManagerModules.default
  ];

  services.vicinae = {
    enable = true;
    systemd = {
      enable = true; # default: false
      autoStart = true; # default: false
      environment = {
        USE_LAYER_SHELL = 1;
      };
    };
    package = perSystem.vicinae.default;
    extensions = with perSystem.vicinae-extensions; [
      bluetooth
      nix
      # systemd
      wifi-commander
      case-converter
      pulseaudio
      process-manager
      port-killer
      niri
    ];
    settings = {
      favicon_service = "twenty";
      font.normal = {
        size = 11;
        normal = config.user.font;
      };
      pop_to_root_on_close = false;
      search_files_in_root = false;
      close_on_focus_loss = true;
      theme = {
        dark = {
          name = "vicinae-dark";
          icon_theme = "Papirus";
        };
      };
      launcher_window = {
        opacity = 0.98;
      };
      providers = {
        clipboard = {
          entrypoints = {
            history = {
              preferences = {
                defaultAction = "copy";
              };
            };
          };
        };
        power = {
          entrypoints = {
            power-off = {
              alias = "shutdown";
            };
          };
        };
        applications = {
          entrypoints = {
            clear-notification = {
              alias = "cn";
            };
            notification-center = {
              alias = "nc";
            };
          };
        };
        "@knoopx/nix-0" = {
          entrypoints = {
            home-manager-options = {
              alias = "nh";
            };
            options = {
              alias = "no";
            };
            packages = {
              alias = "np";
            };
          };
        };
      };
    };
  };
}
