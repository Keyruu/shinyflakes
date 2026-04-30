{ config, ... }:
{
  programs.foot = {
    enable = true;
    server.enable = true;
    settings = {
      main = {
        term = "xterm-256color";
        font = "${config.user.font}:size=13";
        pad = "10x10";
      };

      colors-dark = {
        alpha = 0.9;
        blur = true;
        cursor = "282a36 f8f8f2";
        background = "100F0F";
        foreground = "f8f8f2";
        regular0 = "21222c";
        regular1 = "ff5555";
        regular2 = "50fa7b";
        regular3 = "f1fa8c";
        regular4 = "bd93f9";
        regular5 = "ff79c6";
        regular6 = "8be9fd";
        regular7 = "f8f8f2";
        bright0 = "6272a4";
        bright1 = "ff6e6e";
        bright2 = "69ff94";
        bright3 = "ffffa5";
        bright4 = "d6acff";
        bright5 = "ff92df";
        bright6 = "a4ffff";
        bright7 = "ffffff";
      };

      scrollback = {
        lines = 10000;
        multiplier = 3;
      };

      mouse = {
        alternate-scroll-mode = false;
      };

      bell = {
        visual = true;
        command-focused = false;
      };

      key-bindings = {
        show-urls-launch = "Control+Shift+e";
      };
    };
  };
}
