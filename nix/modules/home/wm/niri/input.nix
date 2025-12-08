_:
# kdl
''
  input {
      keyboard {
          xkb {
              layout "eu"
              options "caps:escape"
          }
          repeat-delay 300
          repeat-rate 50
      }

      touchpad {
          dwt
          dwtp
          tap
          click-method "clickfinger"
      }

      mouse {
          accel-speed -1.0
      }

      focus-follows-mouse max-scroll-amount="10%"

      warp-mouse-to-focus
  }
''
