{ ... }:
''
  layout {
      focus-ring {
          off
          width 1
          active-color "#003a6a"
          inactive-color "#45475a"
      }

      border {
          on
          width 3
          active-color "#4079d6"
          inactive-color "#45475a"
      }

      shadow {
          on
      }

      preset-column-widths {
          proportion 0.333
          proportion 0.5
          proportion 0.666
          proportion 1.0
      }

      default-column-width { proportion 1.0; }

      always-center-single-column
      center-focused-column "on-overflow"

      gaps 4

      struts {
          left 0
          right 0
          top 0
          bottom 0
      }
  }
''
