{
  theme = "kanagawa";
  editor = {
    auto-format = true;

    bufferline = "always";

    color-modes = true;

    lsp.display-inlay-hints = true;
    end-of-line-diagnostics = "hint";
    inline-diagnostics.cursor-line = "warning";

    indent-guides.render = true;

    gutters.layout = [
      "diff"
      "diagnostics"
      "line-numbers"
      "spacer"
    ];
    cursor-shape.insert = "bar";
  };

  keys = {
    normal = {
      "-" = [
        ":sh rm -f /tmp/unique-file"
        ":insert-output yazi '%{buffer_name}' --chooser-file=/tmp/unique-file"
        ":sh printf '\x1b[?1049h\x1b[?2004h' > /dev/tty"
        ":open %sh{cat /tmp/unique-file}"
        ":redraw"
      ];
      " " = {
        l = [
          ":new"
          ":insert-output env -u XDG_CONFIG_HOME lazygit"
          ":buffer-close!"
          ":redraw"
        ];
        q = [
          ":bc"
        ];
      };
      "H" = [ ":buffer-previous" ];
      "L" = [ ":buffer-next" ];
    };
  };
}
