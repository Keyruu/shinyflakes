{ pkgs, ... }:
{
  home.packages = with pkgs; [
    clipse
  ];

  home.file.".config/clipse/config.json".text = # json
    ''
      {
        "historyFile": "clipboard_history.json",
        "maxHistory": 100,
        "allowDuplicates": false,
        "themeFile": "custom_theme.json",
        "tempDir": "tmp_files",
        "logFile": "clipse.log",
        "keyBindings": {
          "choose": "enter",
          "clearSelected": "S",
          "down": "down",
          "end": "end",
          "filter": "/",
          "home": "home",
          "more": "?",
          "nextPage": "right",
          "prevPage": "left",
          "preview": "t",
          "quit": "q",
          "remove": "x",
          "selectDown": "ctrl+down",
          "selectSingle": "s",
          "selectUp": "ctrl+up",
          "togglePin": "p",
          "togglePinned": "tab",
          "up": "up",
          "yankFilter": "ctrl+s"
         },
        "imageDisplay": {
          "type": "sixel",
          "scaleX": 9,
          "scaleY": 9,
          "heightCut": 2
        }
      }
    '';
}
