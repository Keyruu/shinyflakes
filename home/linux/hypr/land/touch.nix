{ pkgs, inputs, ... }:
{
  wayland.windowManager.hyprland = {
    plugins = [
      inputs.hyprgrass.packages.${pkgs.system}.default
      inputs.hyprgrass.packages.${pkgs.system}.hyprgrass-pulse
    ];

    settings.plugins = {
      touch_gestures = {
        hyprgrass-bind = [
          ", edge:d:u, exec, pkill squeekboard || SQUEEKBOARD_DEBUG=force_show squeekboard"
          ", edge:u:d, exec, pkill nwg-drawer || nwg-drawer"
          ", swipe:4:l, movetoworkspace, +1"
          ", swipe:4:r, movetoworkspace, -1"
          ", swipe:4:u, fullscreen"
          ", swipe:4:d, killactive"
        ];

        hyprgrass-bindm = [
          ", longpress:2, movewindow"
          ", longpress:3, resizewindow"
        ];
      };

      hyprgrass-pulse = {
        edge = "r";
      };
    };
  };
}
