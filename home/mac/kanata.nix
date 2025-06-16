{ pkgs, ... }:
let
  kanata = toString (
    pkgs.writeShellScriptBin "kanata-tray-script" # sh
      ''
        #!/bin/sh
        KANATA_TRAY_LOG_DIR=/tmp/ KANATA_TRAY_CONFIG_DIR=~/.config/kanata sudo -E kanata-tray
      ''
  );
in
{
  home.file.".config/kanata/default.kbd".source = ../common/kanata.kbd;

  launchd.agents.kanata = {
    enable = true;
    config = {
      Program = kanata;
      KeepAlive = true;
      RunAtLoad = true;
    };
  };
}
