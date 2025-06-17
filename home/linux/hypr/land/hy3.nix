{pkgs, inputs, ...}: {
  wayland.windowManager.hyprland = {
    plugins = [
      inputs.hy3.packages.${pkgs.system}.hy3
    ];

    settings.plugins = {
      hy3 = {
        no_gaps_when_only = 0;
      };
    };
  };
}

