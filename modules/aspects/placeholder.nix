# Public placeholder for aspects that are fully defined in the
# privateflakes/agents git submodules (modules/aspects/private/ and
# modules/aspects/agents/). This file ensures flake eval works for
# collaborators who clone without `--recurse-submodules` — `with`-style
# references in default.nix files and direct `den.aspects.*` lookups can
# resolve to these empty aspects instead of throwing `undefined variable`
# or `attribute missing`. The submodules merge into the same keys when
# they're fetched.
{ ... }: {
  den.aspects.tools.syncthing = { };

  # agents/ submodule only — lucas.nix references these directly
  den.aspects.agents.pi = { };
  den.aspects.agents.opencode = { };
  den.aspects.agents.claude-code = { };
}