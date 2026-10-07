{ inputs, ... }:
{
  den.aspects.tools.vicinae = {
    nixos = { ... }: {
      imports = [
        inputs.vicinae.nixosModules.default
      ];
    };

    homeManager =
      {
        lib,
        config,
        user,
        inputs',
        self',
        pkgs,
        ...
      }:
      {
        imports = [
          inputs.vicinae.homeManagerModules.default
        ];

        xdg.desktopEntries.vicinae-deeplink = {
          name = "Vicinae Deeplink Handler";
          exec = "vicinae %u";
          icon = "vicin.ae";
          categories = [
            "System"
            "Utility"
          ];
          genericName = "Vicinae Deeplink Handler";
          comment = "Open Vicinae Deeplinks";
          noDisplay = true;
          mimeType = [
            "x-scheme-handler/vicinae"
            "x-scheme-handler/raycast"
            "x-scheme-handler/com.raycast"
          ];
        };

        programs.vicinae = {
          enable = true;
          themes.shinyflakes =
            let
              t = user.theme;
            in
            {
              meta = {
                version = 1;
                name = "Shinyflakes";
                description = "Shared shinyflakes palette";
                variant = "dark";
                inherits = "vicinae-dark";
              };
              colors = {
                core = {
                  inherit (t) background;
                  inherit (t) foreground;
                  secondary_background = t.surface;
                  inherit (t) border;
                  inherit (t) accent;
                  accent_foreground = t.onAccent;
                };
                accents = {
                  blue = t.colors.blue;
                  green = t.colors.green;
                  magenta = t.colors.magenta;
                  orange = t.colors.orange;
                  purple = t.colors.purple;
                  red = t.colors.red;
                  yellow = t.colors.yellow;
                  cyan = t.colors.cyan;
                };
                main_window = {
                  inherit (t) border;
                  footer.background = t.surface;
                };
                settings_window.border = t.border;
                shortcut.border = t.border;
                text = {
                  default = t.foreground;
                  inherit (t) muted;
                  danger = t.colors.red;
                  success = t.colors.green;
                  placeholder = t.muted;
                  links = {
                    default = t.accent;
                    visited = t.colors.purple;
                  };
                  selection = {
                    background = t.accent;
                    foreground = t.onAccent;
                  };
                };
                input = {
                  inherit (t) border;
                  border_focus = t.accent;
                  border_error = t.colors.red;
                };
                button.primary = {
                  background = t.accent;
                  foreground = t.onAccent;
                  hover.background = t.accent;
                  hover.foreground = t.onAccent;
                  focus.outline = t.accent;
                };
                list.item = {
                  hover = {
                    background = t.surface;
                    inherit (t) foreground;
                    secondary_foreground = t.muted;
                  };
                  selection = {
                    background = t.elevated;
                    inherit (t) foreground;
                    secondary_background = t.surface;
                    secondary_foreground = t.muted;
                  };
                };
                grid.item = {
                  selection.outline = t.accent;
                  hover.outline = t.border;
                  background = t.surface;
                };
                scrollbars = {
                  background = t.border;
                  secondary_background = t.surface;
                };
                tooltip = {
                  background = t.surface;
                  inherit (t) foreground border;
                };
                loading = {
                  bar = t.accent;
                  spinner = t.accent;
                };
              };
            };

          systemd = {
            enable = true;
            autoStart = true;
            # Qt's default RHI backend is OpenGL via EGL. The mesa EGL vendor
            # (libEGL_mesa) pulls in libgallium-26.2.3, which needs GLIBC_2.43
            # symbols — but vicinae-server's RUNPATH pins glibc 2.42, so the
            # dlopen of libgallium fails with "version lookup error", EGL init
            # aborts, and Qt's OpenGL RHI falls back through backends to a FATAL
            # abort on window show. Vulkan RHI bypasses the libEGL → libgallium
            # chain entirely (vulkan-icd-loader → mesa vulkan ICDs), so the
            # mesa/glibc mismatch doesn't bite.
            environment = {
              USE_LAYER_SHELL = 1;
              QSG_RHI_BACKEND = "vulkan";
            };
          };

          package = inputs'.vicinae.packages.default;
          extensions =
            (with inputs'.vicinae-extensions.packages; [
              agenda
              # bluetooth
              nix
              # systemd
              wifi-commander
              case-converter
              pulseaudio
              process-manager
              port-killer
              niri
            ])
            ++ (with self'.packages; [
              raycast-karakeep
              raycast-password-generator
              raycast-quick-calendar
              raycast-gif-search
            ]);
          settings = {
            favicon_service = "twenty";
            font.normal = {
              size = 11;
              normal = user.theme.font;
            };
            pop_to_root_on_close = false;
            search_files_in_root = false;
            close_on_focus_loss = true;
            theme = {
              dark = {
                name = "shinyflakes";
                icon_theme = "Papirus";
              };
            };
            launcher_window = {
              opacity = 0.90;
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
                  foot = {
                    alias = "t";
                  };
                  slack = {
                    alias = "s";
                  };
                  spotify = {
                    alias = "m";
                  };
                  zen-beta = {
                    alias = "b";
                  };
                };
              };
              "@knoopx/vicinae-extension-nix-0" = {
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

        xdg.dataFile."vicinae/shortcuts/shortcuts.json".text = builtins.toJSON [
          {
            id = "sct-kagi";
            name = "Kagi";
            icon = "icon://favicon/kagi.com?fallback=icon://omnicast/image?fill%3Dprimary-text";
            url = "https://kagi.com/search?q={argument}";
            app = "default";
          }
        ];

        home.file =
          let
            scripts = ".local/share/vicinae/scripts";
          in
          {
            # silent mode: the script re-opens vicinae itself via `vicinae dmenu`,
            # so no terminal window is wanted
            "${scripts}/mesh-tunnel.sh".source =
              pkgs.writeScript "mesh-tunnel-dmenu" # bash
                ''
                  #!${pkgs.runtimeShell}
                  # @vicinae.schemaVersion 1
                  # @vicinae.title Mesh Tunnel
                  # @vicinae.mode silent
                  # @vicinae.icon 🔒
                  exec ${lib.getExe self'.packages.mesh-tunnel} --dmenu
                '';
            "${scripts}/pi-herd.sh".source =
              pkgs.writeScript "pi-herd-dmenu" # bash
                ''
                  #!${pkgs.runtimeShell}
                  # @vicinae.schemaVersion 1
                  # @vicinae.title Pi Herd
                  # @vicinae.mode silent
                  # @vicinae.icon 🐑
                  exec ${lib.getExe self'.packages.pi-herd} --dmenu
                '';
            "${scripts}/zs.sh".source =
              pkgs.writeScript "zs-dmenu" # bash
                ''
                  #!${pkgs.runtimeShell}
                  # @vicinae.schemaVersion 1
                  # @vicinae.title Zellij Sessions
                  # @vicinae.mode silent
                  # @vicinae.icon 🖥️
                  exec ${lib.getExe self'.packages.zs} --dmenu
                '';
          };
      };
  };
}
