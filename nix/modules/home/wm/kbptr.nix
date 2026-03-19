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
      label_color=#ffffffee
      label_select_color=#f5a623ff
      unselectable_bg_color=#1a1a2688
      selectable_bg_color=#2a2d3aaa
      selectable_border_color=#5b8cffcc
      label_font_family=${config.user.font}
      label_symbols=abcdefghijklmnopqrstuvwxyz

      [mode_click]
      button=left
    '';
}
