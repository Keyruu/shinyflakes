_: {
  programs.foot = {
    enable = true;
    settings = {
      main = {
        term = "xterm-256color";
        font = "monospace:size=12";
        pad = "12x8";
      };

      colors = {
        # dracula theme with custom bg color
        cursor = "282a36 f8f8f2";
        background = "101116";
        foreground = "f8f8f2";
        regular0 = "000000"; # black
        regular1 = "ff5555"; # red
        regular2 = "50fa7b"; # green
        regular3 = "f1fa8c"; # yellow
        regular4 = "bd93f9"; # blue
        regular5 = "ff79c6"; # magenta
        regular6 = "8be9fd"; # cyan
        regular7 = "bfbfbf"; # white
        bright0 = "4d4d4d"; # bright black
        bright1 = "ff6e67"; # bright red
        bright2 = "5af78e"; # bright green
        bright3 = "f4f99d"; # bright yellow
        bright4 = "caa9fa"; # bright blue
        bright5 = "ff92d0"; # bright magenta
        bright6 = "9aedfe"; # bright cyan
        bright7 = "e6e6e6"; # bright white
      };
      scrollback = {
        lines = 10000;
        multiplier = 3;
      };
      mouse = {
        alternate-scroll-mode = false;
      };
      key-bindings = {
        show-urls-launch = "Alt_L";
      };
    };
  };
}
