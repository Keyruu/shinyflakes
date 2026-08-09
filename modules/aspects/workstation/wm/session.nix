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
