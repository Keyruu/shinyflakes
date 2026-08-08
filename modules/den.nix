# Den entry point — the equivalent of blueprint's auto-discovery root.
#
# Currently a skeleton. Phase 1 only wires the framework; hosts and shared
# modules move in phases 2–3. Keep this file minimal until then.
#
# Conventions:
# - Universal flake modules (sops-nix, lanzaboote, home-manager) go in
#   top-level `imports` so every host gets them.
# - Aspect-internal flake module imports (e.g. sops for a single user
#   concern) go inside the aspect's `{ nixos = { imports = [...]; }; }`.
# - Aspects inside dedicated namespaces (`apps`, `stacks`) live under
#   `modules/<namespace>/<name>.nix` and reference via `<namespace/<name>>`.
# - Aspects that are pure cross-cutting concerns live at top level
#   (`modules/aspects/<name>.nix` or `modules/<name>.nix`) and reference
#   via `<name>` or `den.aspects.<name>`.

{
  inputs,
  den,
  lib,
  __findFile,
  ...
}:
{
  # Angle-bracket syntax: <secrets> === den.aspects.secrets, <stacks/immich> === stacks.immich.
  _module.args.__findFile = den.lib.__findFile;

  imports = [
    inputs.den.flakeModule
    (inputs.den.namespace "apps" false)
    (inputs.den.namespace "stacks" false)
  ];

  # Every user gets homeManager by default. Override per-user via
  # `den.hosts.<sys>.<host>.users.<name>.classes = [ ... ];`.
  den.schema.user.classes = lib.mkDefault [ "homeManager" ];

  # No hosts yet — Phase 2 adds den.hosts.x86_64-linux.<name> declarations.
}
