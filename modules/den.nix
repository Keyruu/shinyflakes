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
  # Angle-bracket `<X>` syntax. Set once here; child files that use
  # `<X>` declare `__findFile` in their function args to bring it into
  # lexical scope. See den docs: angle-brackets.mdx.
  _module.args.__findFile = den.lib.__findFile;

  imports = [
    inputs.den.flakeModule
    (inputs.den.namespace "apps" false)
    (inputs.den.namespace "stacks" false)
  ];

  # Every user gets homeManager by default. Override per-user via
  # `den.hosts.<sys>.<host>.users.<name>.classes = [ ... ];`.
  den.schema.user.classes = lib.mkDefault [ "homeManager" ];

  # Auto-provision OS user (account + home dir) and grant wheel + networkmanager
  # to every user entity that opts in. Per-host extraGroups are layered on top
  # by the host's aspect.
  den.schema.host.includes = [
    den.batteries.define-user
    den.batteries.primary-user
  ];

  # Shared defaults applied to every host/user/home via den.default.
  # Per-host overrides still win via den.aspects.<host>.nixos.* priority.
  den.default = {
    nixos.system.stateVersion = "26.05";
    homeManager.home.stateVersion = "26.11";
  };

  # Hosts.
  den.hosts.x86_64-linux.carryall.users.lucas = { };

  den.schema.flake-system.includes = [ den.policies.system-to-flake-parts ];
  den.schema.flake-system.excludes = [ den.policies.packages-to-flake ];
}
