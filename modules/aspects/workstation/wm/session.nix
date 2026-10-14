{ ... }: {
  den.aspects.workstation.wm.session = {
    nixos =
      {
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
            # The session command itself is chosen by the wm aspect (niri sets
            # mkDefault niri-session, mango mkForces mango).
            default_session.user = "${user.userName}";
            initial_session.user = "${user.userName}";
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

            omarchy who? fuck dhh.
          '';

        security.pam.services = {
          login.fprintAuth = false;
          greetd.fprintAuth = false;
        };
      };
  };
}
