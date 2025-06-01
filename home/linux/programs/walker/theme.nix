{ config, ... }:
{
  home.file.".config/walker/themes/shiny.css".text = # css
    ''
      @define-color foreground rgba(255, 255, 255, 0.8);
      @define-color background #${config.stylix.base16Scheme.base01};
      @define-color color1 #${config.stylix.base16Scheme.base05};

      #window,
      #box,
      #aiScroll,
      #aiList,
      #search,
      #password,
      #input,
      #prompt,
      #clear,
      #typeahead,
      #list,
      child,
      scrollbar,
      slider,
      #item,
      #text,
      #label,
      #bar,
      #sub,
      #activationlabel {
        all: unset;
      }

      #cfgerr {
        background: rgba(255, 0, 0, 0.4);
        margin-top: 20px;
        padding: 8px;
        font-size: 1.2em;
      }

      #window {
        color: @foreground;
      }

      #box {
        border-radius: 15px;
        background: @background;
        padding: 32px;
        border: 1px solid lighter(@background);
        box-shadow:
          0 19px 38px rgba(0, 0, 0, 0.3),
          0 15px 12px rgba(0, 0, 0, 0.22);
      }

      #search {
        box-shadow:
          0 1px 3px rgba(0, 0, 0, 0.1),
          0 1px 2px rgba(0, 0, 0, 0.22);
        background: lighter(@background);
        padding: 8px;
      }

      #prompt {
        margin-left: 4px;
        margin-right: 12px;
        color: @foreground;
        opacity: 0.2;
      }

      #clear {
        color: @foreground;
        opacity: 0.8;
      }

      #password,
      #input,
      #typeahead {
        border-radius: 2px;
      }

      #input {
        background: none;
      }

      #password {
      }

      #spinner {
        padding: 8px;
      }

      #typeahead {
        color: @foreground;
        opacity: 0.8;
      }

      #input placeholder {
        opacity: 0.5;
      }

      #list {
      }

      child {
        padding: 8px;
        border-radius: 2px;
      }

      child:selected,
      child:hover {
        background: alpha(@color1, 0.4);
      }

      #item {
      }

      #icon {
        margin-right: 8px;
      }

      #text {
      }

      #label {
        font-weight: 500;
      }

      #sub {
        opacity: 0.5;
        font-size: 0.8em;
      }

      #activationlabel {
      }

      #bar {
      }

      .barentry {
      }

      .activation #activationlabel {
      }

      .activation #text,
      .activation #icon,
      .activation #search {
        opacity: 0.5;
      }

      .aiItem {
        padding: 10px;
        border-radius: 2px;
        color: @foreground;
        background: @background;
      }

      .aiItem.user {
        padding-left: 0;
        padding-right: 0;
      }

      .aiItem.assistant {
        background: lighter(@background);
      }
    '';

  home.file.".config/walker/themes/shiny.toml".text = # toml
    ''
      [ui.anchors]
      bottom = true
      left = true
      right = true
      top = true

      [ui.window]
      h_align = "fill"
      v_align = "fill"

      [ui.window.box]
      h_align = "center"
      width = 450

      [ui.window.box.bar]
      orientation = "horizontal"
      position = "end"

      [ui.window.box.bar.entry]
      h_align = "fill"
      h_expand = true

      [ui.window.box.bar.entry.icon]
      h_align = "center"
      h_expand = true
      pixel_size = 24
      theme = ""

      [ui.window.box.margins]
      top = 200

      [ui.window.box.ai_scroll]
      name = "aiScroll"
      h_align = "fill"
      v_align = "fill"
      max_height = 300
      min_width = 400
      height = 300
      width = 400

      [ui.window.box.ai_scroll.margins]
      top = 8

      [ui.window.box.ai_scroll.list]
      name = "aiList"
      orientation = "vertical"
      width = 400
      spacing = 10

      [ui.window.box.ai_scroll.list.item]
      name = "aiItem"
      h_align = "fill"
      v_align = "fill"
      x_align = 0
      y_align = 0
      wrap = true

      [ui.window.box.scroll.list]
      marker_color = "#1BFFE1"
      max_height = 300
      max_width = 400
      min_width = 400
      width = 400

      [ui.window.box.scroll.list.item.activation_label]
      h_align = "fill"
      v_align = "fill"
      width = 20
      x_align = 0.5
      y_align = 0.5

      [ui.window.box.scroll.list.item.icon]
      pixel_size = 26
      theme = ""

      [ui.window.box.scroll.list.margins]
      top = 8

      [ui.window.box.search.prompt]
      name = "prompt"
      icon = "edit-find"
      theme = ""
      pixel_size = 18
      h_align = "center"
      v_align = "center"

      [ui.window.box.search.clear]
      name = "clear"
      icon = "edit-clear"
      theme = ""
      pixel_size = 18
      h_align = "center"
      v_align = "center"

      [ui.window.box.search.input]
      h_align = "fill"
      h_expand = true
      icons = true

      [ui.window.box.search.spinner]
      hide = true
    '';
}
