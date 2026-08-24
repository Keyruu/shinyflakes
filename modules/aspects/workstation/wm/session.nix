{ ... }: {
  den.aspects.workstation.wm.session = {
    nixos =
      {
        inputs',
        user,
        ...
      }:
      {
        services.greetd = {
          enable = true;
          settings = {
            terminal.vt = 1;
            # Auto-login: same session for both default and initial, so greetd
            # never spawns a greeter and skips the PAM password prompt.
            default_session = {
              command = "${inputs'.niri.packages.niri-unstable}/bin/niri-session";
              user = "${user.userName}";
            };
            initial_session = {
              command = "${inputs'.niri.packages.niri-unstable}/bin/niri-session";
              user = "${user.userName}";
            };
          };
        };

        environment.etc."issue".text = # env
          ''
            ███▄▄▄▄    ▄█  ▀████     ████▀  ▄██████▄     ▄████████
            ███▀▀▀██▄ ███    ███    ████▀  ███    ███   ███    ███
            ███   ███ ███     ███   ███    ███    ███   ███    █▀
            ███   ███ ███     ▀███▄███▀    ███    ███   ███
            ███   ███ ███     ████▀██▄     ███    ███ ▀███████████
            ███   ███ ███     ███  ▀███    ███    ███          ███
            ███   ███ ███   ▄███     ███▄  ███    ███    ▄█    ███
             ▀█   █▀  █▀   ████       ███▄  ▀██████▀   ▄████████▀

            omarchy who?
          '';

        security.pam.services = {
          login.fprintAuth = false;
          greetd.fprintAuth = false;
        };
      };
  };
}
