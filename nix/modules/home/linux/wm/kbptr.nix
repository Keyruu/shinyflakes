{ config, pkgs, ... }:
{
  home.packages = with pkgs; [
    wl-kbptr
    wlrctl
  ];

  home.file.".config/wl-kbptr/floating".text = # toml
    ''
      [general]
      home_row_keys=
      modes=floating,click

      [mode_floating]
      source=detect
      label_color=#fffd
      label_select_color=#fd0d
      unselectable_bg_color=#2226
      selectable_bg_color=#171a
      selectable_border_color=#040c
      label_font_family=${config.user.font}
      label_symbols=abcdefghijklmnopqrstuvwxyz

      [mode_click]
      button=left
    '';
}
