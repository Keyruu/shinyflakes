{
  programs.satty = {
    enable = true;
    settings.general = {
      early-exit = true;
      copy-command = "wl-copy";
      initial-tool = "rectangle";
      actions-on-enter = [ "save-to-clipboard" ];
      actions-on-escape = [ "exit" ];
      corner-roundness = 12;
    };
  };
}
