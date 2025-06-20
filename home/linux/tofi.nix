{ config, ... }:
{
  programs.tofi = {
    enable = true;
    settings = {
      # Window appearance
      width = 600;
      height = 400;
      border-width = 2;
      outline-width = 0;
      padding-left = 20;
      padding-right = 20;
      padding-top = 20;
      padding-bottom = 20;
      corner-radius = config.theme.rounding;

      # Behavior
      num-results = 8;
      result-spacing = 8;
      horizontal = false;
      anchor = "center";
      exclusive-zone = -1;
      hide-cursor = true;
      text-cursor = false;
      history = true;
      fuzzy-match = true;
      require-match = true;
      auto-accept-single = false;
      hide-input = false;
      hidden-character = "*";
      drun-launch = true;
      terminal = "foot";
      late-keyboard-init = false;
      multi-instance = false;
      ascii-input = false;
    };
  };
}
