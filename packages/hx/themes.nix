{
  kanagawa =
    let
      # bg shades — user-overridden darker variants from theme.lua
      sumiInk0 = "#0c0e0f";
      sumiInk1 = "#0e1011";
      sumiInk2 = "#101213";
      sumiInk3 = "#121415";
      sumiInk4 = "#141617";
      sumiInk5 = "#161819";
      sumiInk6 = "#54546D";

      # fg
      fujiWhite = "#DCD7BA";
      oldWhite = "#dae1e6"; # user override
      fujiGray = "#727169";

      # popups / selection
      waveBlue1 = "#223249";
      waveBlue2 = "#2D4F67";

      # syntax
      springGreen = "#98BB6C";
      sakuraPink = "#D27E99";
      surimiOrange = "#FFA066";
      carpYellow = "#E6C384";
      oniViolet2 = "#b8b4d0";
      crystalBlue = "#7E9CD8";
      oniViolet = "#957FB8";
      boatYellow2 = "#C0A36E";
      waveRed = "#E46876";
      waveAqua2 = "#7AA89F";
      springViolet1 = "#938AA9";
      springViolet2 = "#9CABCA";
      springBlue = "#7FB4CA";
      katanaGray = "#717C7C";

      # vcs / diff
      autumnGreen = "#76946A";
      autumnRed = "#C34043";
      autumnYellow = "#DCA561";

      # diagnostics
      samuraiRed = "#E82424";
      roninYellow = "#FF9E3B";
      waveAqua1 = "#6A9589";
      dragonBlue = "#658594";
    in
    {
      # transparent bg: matches kanagawa transparent=true
      "ui.background" = { };

      "ui.text" = {
        fg = fujiWhite;
      };
      "ui.text.focus" = {
        fg = oldWhite;
        modifiers = [ "bold" ];
      };

      "ui.cursor" = {
        modifiers = [ "reversed" ];
      };
      "ui.cursor.primary" = {
        modifiers = [ "reversed" ];
      };
      "ui.cursor.match" = {
        fg = boatYellow2;
        modifiers = [ "underlined" ];
      };

      "ui.selection" = {
        bg = waveBlue1;
      };
      "ui.selection.primary" = {
        bg = waveBlue1;
      };

      "ui.linenr" = {
        fg = sumiInk6;
      };
      "ui.linenr.selected" = {
        fg = fujiWhite;
      };

      "ui.statusline" = {
        fg = fujiWhite;
        bg = waveBlue1;
      };
      "ui.statusline.inactive" = {
        fg = sumiInk6;
        bg = sumiInk1;
      };

      "ui.popup" = {
        bg = sumiInk0;
      };
      "ui.popup.info" = {
        bg = sumiInk0;
      };

      "ui.window" = {
        fg = sumiInk6;
      };
      "ui.help" = {
        fg = oldWhite;
        bg = sumiInk0;
      };

      "ui.menu" = {
        fg = fujiWhite;
        bg = waveBlue1;
      };
      "ui.menu.selected" = {
        bg = waveBlue2;
        modifiers = [ "bold" ];
      };
      "ui.menu.scroll" = {
        fg = fujiWhite;
        bg = waveBlue1;
      };

      "ui.virtual" = {
        fg = sumiInk6;
      };
      "ui.virtual.indent-guide" = {
        fg = sumiInk6;
      };
      "ui.virtual.whitespace" = {
        fg = sumiInk6;
      };
      "ui.virtual.inlay-hint" = {
        fg = springViolet1;
      };
      "ui.virtual.ruler" = {
        bg = sumiInk4;
      };

      "attribute" = carpYellow;
      "comment" = {
        fg = fujiGray;
      };
      "comment.block.documentation" = {
        fg = springViolet1;
      };
      "constant" = surimiOrange;
      "constant.builtin" = surimiOrange;
      "constant.numeric" = sakuraPink;
      "constant.character" = springGreen;
      "constant.character.escape" = waveRed;
      "constructor" = oniViolet;
      "function" = crystalBlue;
      "function.builtin" = crystalBlue;
      "function.macro" = waveRed;
      "keyword" = oniViolet;
      "keyword.control" = oniViolet;
      "keyword.directive" = waveRed;
      "keyword.function" = oniViolet;
      "keyword.operator" = boatYellow2;
      "keyword.storage" = oniViolet;
      "label" = oniViolet;
      "namespace" = springViolet2;
      "operator" = boatYellow2;
      "special" = springBlue;
      "string" = springGreen;
      "string.special" = waveRed;
      "type" = waveAqua2;
      "type.builtin" = waveAqua2;
      "variable" = fujiWhite;
      "variable.builtin" = springViolet1;
      "variable.parameter" = oniViolet2;
      "variable.other.member" = carpYellow;

      "markup" = {
        fg = oldWhite;
      };
      "markup.heading" = crystalBlue;
      "markup.heading.marker" = sumiInk6;
      "markup.bold" = {
        fg = carpYellow;
        modifiers = [ "bold" ];
      };
      "markup.italic" = {
        fg = carpYellow;
        modifiers = [ "italic" ];
      };
      "markup.link" = springBlue;
      "markup.link.url" = springBlue;
      "markup.link.text" = carpYellow;
      "markup.list" = waveRed;
      "markup.quote" = {
        fg = fujiGray;
      };
      "markup.raw" = surimiOrange;

      "diff.plus" = autumnGreen;
      "diff.minus" = autumnRed;
      "diff.delta" = autumnYellow;
      "diff.delta.moved" = carpYellow;

      "error" = samuraiRed;
      "warning" = roninYellow;
      "info" = dragonBlue;
      "hint" = waveAqua1;
      "debug" = katanaGray;
      "diagnostic.error" = {
        underline = {
          style = "line";
          color = samuraiRed;
        };
      };
      "diagnostic.warning" = {
        underline = {
          style = "line";
          color = roninYellow;
        };
      };
      "diagnostic.info" = {
        underline = {
          style = "line";
          color = dragonBlue;
        };
      };
      "diagnostic.hint" = {
        underline = {
          style = "line";
          color = waveAqua1;
        };
      };
    };
}
