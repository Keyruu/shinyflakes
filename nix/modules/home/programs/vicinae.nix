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
      # doesnt work for some reason
      # (perSystem.vicinae.mkRayCastExtension {
      #   name = "karakeep";
      #   sha256 = "sha256-DAfDI2wxZ7mkpbQ+C0Y2xEaWZ98SiEPj6S/q8xlyRC8=";
      #   rev = "3f7bf4d8f11dda61d1da77ddd4c0e67eb997d099";
      # })
      # (perSystem.vicinae.mkRayCastExtension {
      #   name = "password-generator";
      #   sha256 = "sha256-VbC6h6TuvPlnPvVGs23pefw4a4musuZI+wTUg9v+9jk=";
      #   rev = "3f7bf4d8f11dda61d1da77ddd4c0e67eb997d099";
      # })
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
