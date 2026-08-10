# Den entry point. Per the den convention, leaf aspects live under
# `modules/aspects/<domain>/<name>.nix` and umbrellas at
# `modules/aspects/<name>.nix`. Cross-references use direct
# `den.aspects.<domain>.<name>` (no angle-bracket sugar).

{
  inputs,
  den,
  lib,
  ...
}:
{
  imports = [
    inputs.den.flakeModule
  ];

  # debug
  flake.den = den;

  # Every user gets homeManager by default. Override per-user via
  # `den.hosts.<sys>.<host>.users.<name>.classes = [ ... ];`.
  den.schema.user.classes = lib.mkDefault [ "homeManager" ];

  # Auto-provision OS user (account + home dir) and grant wheel + networkmanager
  # to every user entity that opts in. Per-host extraGroups are layered on top
  # by the host's aspect.
  den.schema.host.includes = [
    den.batteries.define-user
    den.batteries.primary-user

    den.aspects.options.my.services
    den.aspects.options.my.stack
  ];

  # Shared defaults applied to every host/user/home via den.default.
  # Per-host overrides still win via den.aspects.<host>.nixos.* priority.
  den.default = {
    nixos.system.stateVersion = "26.05";
    homeManager.home.stateVersion = "26.11";

    includes = [
      # Sets the system hostname as defined in `den.hosts.<name>.hostName`
      den.batteries.hostname

      # Provides inputs' (the flake’s inputs with system pre-selected) as a top-level module argument.
      den.batteries.inputs'

      # Provides self' (the flake’s self outputs with system pre-selected) as a top-level module argument.
      den.batteries.self'

      den.aspects.options.my.services
      den.aspects.options.my.stack
    ];
  };

  # Hosts are declared in their own modules/hosts/<host>/default.nix.

  den.schema.flake-system.includes = [ den.policies.system-to-flake-parts ];
  den.schema.flake-system.excludes = [ den.policies.packages-to-flake ];
}
