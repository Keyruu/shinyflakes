{ lib, ... }:
{
  options = {
    user = {
      name = lib.mkOption {
        type = lib.types.str;
        description = "Primary user name";
      };
      font = lib.mkOption {
        type = lib.types.str;
        description = "Primary Font to use";
        default = "Maple Mono Normal NL NF";
      };
      theme = lib.mkOption {
        description = "Shared color palette consumed by themed programs (noctalia, vicinae, ...).";
        type = lib.types.submodule {
          options = {
            background = lib.mkOption {
              type = lib.types.str;
              default = "#111111";
              description = "Primary background.";
            };
            surface = lib.mkOption {
              type = lib.types.str;
              default = "#1E1E1E";
              description = "Secondary background (cards, sidebars).";
            };
            elevated = lib.mkOption {
              type = lib.types.str;
              default = "#262626";
              description = "Raised element background, one step above surface.";
            };
            border = lib.mkOption {
              type = lib.types.str;
              default = "#3c3c3c";
              description = "Subtle border/outline.";
            };
            foreground = lib.mkOption {
              type = lib.types.str;
              default = "#cdd6f4";
              description = "Primary text color.";
            };
            muted = lib.mkOption {
              type = lib.types.str;
              default = "#828282";
              description = "Muted/secondary text color.";
            };
            accent = lib.mkOption {
              type = lib.types.str;
              default = "#4079d6";
              description = "Primary accent.";
            };
            onAccent = lib.mkOption {
              type = lib.types.str;
              default = "#111111";
              description = "Text color drawn on top of accent fills.";
            };
            colors = lib.mkOption {
              description = "Named accent palette.";
              type = lib.types.submodule {
                options = {
                  red = lib.mkOption {
                    type = lib.types.str;
                    default = "#f38ba8";
                  };
                  green = lib.mkOption {
                    type = lib.types.str;
                    default = "#a6e3a1";
                  };
                  yellow = lib.mkOption {
                    type = lib.types.str;
                    default = "#f9e2af";
                  };
                  blue = lib.mkOption {
                    type = lib.types.str;
                    default = "#89b4fa";
                  };
                  magenta = lib.mkOption {
                    type = lib.types.str;
                    default = "#f5c2e7";
                  };
                  purple = lib.mkOption {
                    type = lib.types.str;
                    default = "#cba6f7";
                  };
                  orange = lib.mkOption {
                    type = lib.types.str;
                    default = "#fab387";
                  };
                  cyan = lib.mkOption {
                    type = lib.types.str;
                    default = "#94e2d5";
                  };
                };
              };
              default = { };
            };
          };
        };
        default = { };
      };
    };
  };
}
