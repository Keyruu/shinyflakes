# Shinyflakes Instructions

## Project Structure

This repo uses [den](https://github.com/denful/den)
(dendritic style). All Nix code lives under `modules/` — every `.nix` file
there is a flake-parts module, loaded automatically by
[import-tree](https://github.com/denful/import-tree). There is no manual
import list; adding a file under `modules/` is enough to wire it in. `flake.nix`
only does:

```nix
outputs = inputs:
  let
    flake = inputs.flake-parts.lib.mkFlake { inherit inputs; } (inputs.import-tree ./modules);
  in
  flake // {
    # CI host matrix — every nixosConfiguration except ciSkip (build.yml)
    lib.hostMatrix.host = ...;
  };
```

### Folder Structure

```
modules/
├── den.nix                 # den wiring: schema, den.default (state versions, batteries), policies
├── nh.nix                  # nh helper packages
├── overlays.nix            # nixpkgs overlay (zellij from flake input)
├── packages.nix            # pkgs-by-name wiring for top-level packages/
├── aspects/
│   ├── core/               # every host: common, gc, hardening, locale, nice, nixConfig, podman
│   ├── workstation/        # laptops/desktops only: gaming, kanata, sound, secure-boot, wm/
│   ├── server/             # servers only: caddy, nginx, monitoring/, backup, mesh-server
│   ├── roles/              # composite roles (roles.server bundles core + server aspects)
│   ├── services/           # one aspect per self-hosted service (immich, karakeep, media/, ...)
│   ├── options/            # option-only aspects (no nixos config): options.mesh, options.my.{services,stack}
│   ├── tools/ shell/ editors/ terminals/ browsers/   # user-facing homeManager aspects
│   ├── private/            # git submodule: private data (people, authelia seed, mail, calendar)
│   ├── agents/             # git submodule: AI agent aspects (pi, opencode, claude-code) + skills
│   └── placeholder.nix     # public stubs for submodule-only aspects (see below)
├── hosts/<host>/           # per-host aspect, split across sibling files
├── entities/               # extra entity kinds: people registry (den.people), theme
├── policies/               # den policies: quirk collection (services-collect)
└── users/                  # user aspects (lucas.nix)

packages/                   # custom packages (auto-discovered via pkgs-by-name-for-flake-parts)
secrets.yaml                # SOPS-encrypted secrets (repo root)
```

### Git Tracking + Submodules

- New files must be `git add`ed before eval — import-tree reads the committed
  state, not the working tree. A new file under `modules/` is invisible to
  `nix build`/`nixos-rebuild` until tracked.
- `modules/aspects/private/` and `modules/aspects/agents/` are git submodules.
  Every flake ref needs `?submodules=1`, otherwise evaluation fails with
  missing attributes (`den.people`, agent aspects, private secrets).
- Files whose name starts with `_` are skipped by import-tree — they are
  imported manually (e.g. `hosts/powder/_disk.nix`).

## How Den Works

### Aspects

An aspect is one concern bundled across Nix classes (`nixos`, `homeManager`,
...) into a single attrset. The per-class blocks are plain modules — attrset or
function form, same options, same `mkIf`/`mkForce`:

```nix
# modules/aspects/services/karakeep.nix (abbreviated)
{ ... }: {
  den.aspects.services.karakeep = {
    nixos = { config, ... }: {
      sops.secrets = { ... };
      services.my.karakeep = {
        port = 3000;
        domain = "karakeep.lab.keyruu.de";
      };
    };
  };
}
```

- **`nixos` / `homeManager`** — owned config per class.
- **`includes`** — dependency list of other aspects (a DAG). E.g.
  `den.aspects.core.default` includes `common`, `gc`, `hardening`, `...`;
  `den.aspects.mentat` includes `den.aspects.roles.server` + its services.
- **`provides`** — named sub-aspects, reachable as `den.aspects.<name>.<sub>`
  (e.g. `den.aspects.services.home-assistant.default`).
- **Context args** — the aspect itself can be a function of its scope:
  `den.aspects.<name> = { host, ... }: { ... }` runs per host,
  `{ host, user, ... }:` per user, `{ ... }:` once. Dispatch is purely by
  argument shape — no specialArgs tricks.

### Multiple Files per Aspect

Aspects merge through the module system: every file under `modules/` that
writes `den.aspects.<name>.<key>` contributes. Hosts are split across
siblings, all writing `den.aspects.<host>`:

- `modules/hosts/mentat/default.nix` — host registration + `includes`
- `configuration.nix`, `hardware.nix`, `disk.nix`, `mesh.nix`, `nas.nix`,
  `network.nix`, `syncthing.nix`, `cockpit.nix` — each adds
  `den.aspects.mentat.nixos = { ... }`

Same pattern for services: `aspects/services/home-assistant/{home-assistant,mqtt,esphome,zigbee2mqtt,...}.nix`
all write `den.aspects.services.home-assistant`. Split whenever a file grows —
merging is free.

### Hosts and Users

```nix
# modules/hosts/mentat/default.nix
{ den, ... }: {
  # registration: host + its users. Auto-creates den.aspects.mentat,
  # applied to this host automatically.
  den.hosts.x86_64-linux.mentat.users.root.classes = [ ];

  den.aspects.mentat = {
    includes = [
      den.aspects.roles.server
      den.aspects.services.immich
      # ...
    ];
  };
}
```

- Registering a host auto-creates `den.aspects.<host>` (nixos class).
- Registering a user auto-creates `den.aspects.<user>`; every user gets the
  `homeManager` class by default (`den.schema.user.classes` in `den.nix`).
- User config lives in `modules/users/lucas.nix` — includes
  (browsers/shell/editors/...) + `homeManager` block.
- Extra host options are declared via `den.schema.host.options` in `den.nix`
  (e.g. `displays` for kanshi monitor layout, read by the carryall/powder
  hosts).

### Batteries and Defaults

`den.batteries.*` are reusable aspects, most wired via `den.default` in
`modules/den.nix`:

- `hostname` — sets `networking.hostName` from the host name
- `define-user` / `primary-user` — provision the OS user + home dir, wheel +
  networkmanager
- `host-aspects` — project host-aspect homeManager classes onto opted-in users
- `user-shell "fish"` — login shell at OS + home-manager level
- `unfree [ "obsidian" ... ]` — scoped unfree allowances (needs exact
  attr/pname, scope per aspect)
- `inputs'` / `self'` — flake inputs/outputs with system pre-selected

`den.default` also pins state versions once (`nixos = "26.05"`,
`home = "26.11"`) — never set them per host or user.

### Entities: People Registry

`modules/entities/people.nix` declares `den.people` — the identity layer for
mesh + authelia. Per person: `email`, `devices` (mesh wireguard peers: `ip`,
`publicKey`, `allowedIPs`), `canAccess` (named networks for nftables forward
rules), `service-access` (auto-derives authelia `<svc>_users` groups,
policies, OIDC clients, and nginx allowlists). Personal data lives in the
`private` submodule (`aspects/private/people.nix`).

### Quirks and Policies (Service Facts)

Service aspects emit facts through quirks — `den.quirks.dashboard`, `monitor`,
`scrape`, `public-proxy`, `oidc-config` — declared on the `services.my.<name>`
registry. This replaces blueprint's `flake.allMyServices` / `proxyHosts`
plumbing:

```nix
services.my.karakeep = {
  domain = "karakeep.lab.keyruu.de";
  dashboard.groups = [ "karakeep_users" ];
  monitor.conditions = [ "[STATUS] == 403" ];
  oidc = { enable = true; ... };
  proxy.whitelist.enable = true;  # IP allowlist from den.people service-access
};
```

`modules/policies/services-collect.nix` wires `den.policies.collect-service-facts`
into every host, collecting the quirks. Consumers: glance dashboard (mentat),
gatus + prometheus (mentat), authelia clients (prime), public caddy/nginx
proxies (prime). Registering a new service automatically wires monitoring,
dashboard, proxy, and OIDC.

### Placeholder Aspects (`modules/aspects/placeholder.nix`)

Some aspects are only defined inside git submodules
(`aspects/private/`, `aspects/agents/`). Direct references like
`den.aspects.tools.syncthing` would throw `attribute missing` for anyone
cloning without `--recurse-submodules`. `placeholder.nix` declares those keys
as empty aspects (`{ }`) so eval works submodule-less; empty attrsets merge
harmlessly with the real definitions when the submodules are present.

**Rule: any aspect that is only defined in a submodule needs a placeholder
entry.**

### Building and Deploying

**Important:** This flake uses git submodules (e.g. private modules). Every nix
command must include `?submodules=1` in the flake ref, otherwise evaluation
fails with errors like `attribute 'link-bypass' missing`. This applies to
`nixos-rebuild`, `nix build`, `nix eval`, `nix flake check`, etc.

**Build a NixOS configuration:**

```bash
# Build without switching
nixos-rebuild build --flake '.?submodules=1#hostname'

# Build and switch
sudo nixos-rebuild switch --flake '.?submodules=1#hostname'

# Build and test (reverts on reboot)
sudo nixos-rebuild test --flake '.?submodules=1#hostname'

# Eval / other commands
nix eval '.?submodules=1#nixosConfigurations.hostname.config...'

# Inspect den state (hosts, aspects)
nix eval '.?submodules=1#den.hosts' --apply 'builtins.attrNames'
nix eval '.?submodules=1#den.aspects' --apply builtins.attrNames
```

Local hosts also work via `nh` (wired in `modules/nh.nix`).

### Adding a New Host

1. Create `modules/hosts/<hostname>/default.nix`:

```nix
{ den, inputs, ... }:
{
  # registration — auto-creates and applies den.aspects.<hostname>
  den.hosts.x86_64-linux.<hostname>.users.lucas = { };

  den.aspects.<hostname> = {
    includes = [
      den.aspects.roles.server  # or workstation.* for laptops
    ];

    nixos = { pkgs, lib, ... }: {
      imports = [ inputs.nixos-hardware.nixosModules.<module> ];
      nixpkgs.hostPlatform = "x86_64-linux";
    };
  };
}
```

2. Generate hardware configuration:

```bash
nixos-generate-config --root /mnt --show-hardware-config > modules/hosts/<hostname>/hardware.nix
```

Wrap it as `den.aspects.<hostname>.nixos = { config, lib, modulesPath, ... }: { ... }`
(see `modules/hosts/carryall/hardware.nix` for the pattern).

3. Split further as the host grows (`mesh.nix`, `disk.nix`, `nas.nix`) — each
   sibling writes `den.aspects.<hostname>.nixos` and merges automatically.

4. `git add modules/hosts/<hostname>`, then build. Hostname and stateVersion
   come from `den.batteries.hostname` / `den.default` — don't set them.

### Project Conventions

- **Host-specific config** goes in `modules/hosts/<host>/*.nix` (split across
  files, all writing `den.aspects.<host>`)
- **Cross-cutting NixOS concerns** go in `modules/aspects/{core,workstation,server}/`
- **Composite roles** go in `modules/aspects/roles/`
- **Self-hosted services** go in `modules/aspects/services/<name>.nix` via the
  `services.my` registry
- **Option-only modules** go in `modules/aspects/options/**` (just `options.*`,
  no config)
- **Users** go in `modules/users/<user>.nix`
- **Secrets** are in `secrets.yaml` (repo root) and managed with SOPS; private
  data lives in the `aspects/private` submodule
- **Custom packages** go in top-level `packages/`
- Reference aspects directly: `den.aspects.<category>.<name>` — no angle
  brackets, no `flake.modules.*`

## Stack Module (`services.my.<name>.stack`)

The stack module (`modules/aspects/options/my/stack.nix`) reduces boilerplate for
quadlet container stacks by auto-generating tmpfiles, users, networks, backup
wiring, OWASP security hardening, and container orchestration.

### How Stack Containers Work

Containers are defined inside `services.my.<name>.stack.containers` using
**short names** as keys. The stack module auto-prefixes them with the stack name
and copies them into `virtualisation.quadlet.containers`:

```
stack.containers.web      → virtualisation.quadlet.containers.karakeep-web
stack.containers.chrome   → virtualisation.quadlet.containers.karakeep-chrome
stack.containers.db       → virtualisation.quadlet.containers.karakeep-db
```

**Exception:** stacks with exactly **one** container keep the short name
unprefixed (`stack.containers.n8n` → `virtualisation.quadlet.containers.n8n`).
Convention: name the single container after the stack itself to avoid
collisions between stacks. Note that adding a second container later changes
the existing container's name (it becomes prefixed) — update `restartUnits`,
`quadlet.alias` references, and backup units accordingly.

The container options are the same as `virtualisation.quadlet.containers.*`
(reused via `getSubModules`), plus these stack-specific extras:

- **`dependsOn`** — list of sibling short names; auto-generates
  `unitConfig.After` and `unitConfig.Requires` with prefixed refs
- **`security.*`** — per-container overrides for stack-level security settings
  (null = use global)

### What the Stack Module Auto-Generates

When `stack.enable = true`:

- **Directories**: `stack.directories` entries become `systemd.tmpfiles.rules`.
  When `stack.user` is enabled, directories default to user ownership with mode
  `0750`.
- **Users/Groups**: `stack.user` creates `users.users` and `users.groups`.
- **Network**: `stack.network` creates a quadlet bridge network with
  `interfaceName`. The network is auto-wired into all stack containers.
- **Dependencies**: `dependsOn` on each container auto-generates
  `unitConfig.After` and `unitConfig.Requires` with prefixed container refs.
- **Backup**: When `backup.enable = true`, `backup.paths` defaults to
  `[ stack.path ]` and `backup.systemd.unit` is auto-wired from all stack
  containers.
- **Security**: When `stack.security.enable = true`, OWASP hardening is applied
  to all stack containers. Per-container `security.*` options override the
  globals (null = use global). All values use `mkDefault` so explicit
  `containerConfig` values always win.

**Note**: `serviceConfig.Restart = "always"` is already the default in
quadlet-nix, so stacks never need to set it.

### Stack Options Quick Reference

- `stack.enable` — enable stack infrastructure
- `stack.path` — base path (default: `/etc/stacks/<name>`), usable as
  `my.stack.path`
- `stack.directories` — list of subdirs (string or `{ path; mode; owner; group; }`)
- `stack.user.{ enable, name, uid, group, gid, extraGroups }` — system user
- `stack.network.{ enable, name }` — bridge network
- `stack.containers` — attrsOf container submodules (short names, auto-prefixed;
  single-container stacks stay unprefixed — name the container after the stack)
- `stack.containers.<name>.dependsOn` — list of sibling short names for deps
- `stack.containers.<name>.security.*` — per-container security overrides
- `stack.security.{ enable, dropAllCapabilities, noNewPrivileges,
readOnlyRootFilesystem, memoryLimit, pidsLimit }` — stack-level security

## ZFS Encryption & Service Gating

Mentat uses ZFS native encryption on datasets under `main/encrypted`. Datasets
are **not** auto-unlocked at boot — a manual unlock step is required.

### How It Works

1. **Boot**: Server starts normally. Encrypted datasets remain locked and
   unmounted. Services depending on them do not start.
2. **Unlock**: SSH in and run `sudo zfs-unlock`. This loads encryption keys,
   mounts datasets, and activates `zfs-encrypted.target`.
3. **Services start**: All services with `zfs = true` are `wantedBy` the target
   and auto-start once it activates.

### Infrastructure (defined in `modules/hosts/mentat/nas.nix`)

- `zfs-encrypted.target` — systemd target representing "datasets are unlocked"
- `zfs-encrypted-check.service` — oneshot gate that verifies `keystatus =
available` before the target can activate
- `zfs-unlock` — shell script package (`packages/zfs-unlock.nix`) that runs
  `zfs load-key -a`, `zfs mount -a`, and `systemctl start zfs-encrypted.target`

### Service Option: `services.my.<name>.zfs`

Set `zfs = true` on any service that depends on encrypted ZFS datasets:

```nix
services.my.immich = {
  zfs = true;  # wires up zfs-encrypted.target dependency
  port = 2283;
  # ...
};
```

For **stack-based services**, this automatically:

- Adds `After` and `Requires` on `zfs-encrypted.target` to all stack containers
- Adds `wantedBy = [ "zfs-encrypted.target" ]` to all stack container services

For **non-stack services** (e.g., syncthing, copyparty, restic), wire up
manually:

```nix
systemd.services.syncthing = {
  after = [ "zfs-encrypted.target" ];
  requires = [ "zfs-encrypted.target" ];
  wantedBy = [ "zfs-encrypted.target" ];
};
```

## Authelia OIDC (SSO)

Authelia runs on prime (`auth.peeraten.net`). OIDC clients are generated from
the `oidc-config` quirk — every host with
`services.my.<name>.oidc.enable = true` is collected by
`modules/policies/services-collect.nix` and rendered by
`modules/aspects/server/authelia.nix`. The users seed (identity, groups,
password hashes) is generated from `den.people` in
`modules/aspects/private/authelia.nix`.

### Provisioning Scripts (run from repo root)

```bash
# Generate <service>ClientSecret in secrets.yaml (secret is never printed)
# and print the pbkdf2 digest for the authelia client config:
nix run '.?submodules=1#authelia-oidc-client' -- <service>

# Prompt for a password and store its argon2 digest as <user>PasswordHash:
nix run '.?submodules=1#authelia-user-hash' -- <user>
```

### Adding a New OIDC Client

1. **Secret**: `nix run '.?submodules=1#authelia-oidc-client' -- <service>` —
   stores `<service>ClientSecret` in sops, prints the pbkdf2 digest.
2. **Service side**: enable OIDC on the service's registry entry — the client
   is derived from it, not hand-written in authelia.nix:

   ```nix
   services.my.<service>.oidc = {
     enable = true;
     clientSecret = "$pbkdf2-sha512$...";  # digest from step 1
     redirectUris = [ "https://<service>.peeraten.net/api/auth/callback/custom" ];
     # per-app extras: requirePkce, pkceChallengeMethod, tokenEndpointAuthMethod,
     # scopes, claimsPolicy — check https://www.authelia.com/integration/openid-connect/clients/
   };
   ```

   `authorization_policy = "<service>_access"` is set automatically. Named
   claims policies are still declared inline in
   `modules/aspects/server/authelia.nix` (authelia-side config is prime-only).
3. **Access**: add `<service>` to the person's `service-access` in
   `modules/aspects/private/people.nix` — groups + access policy are derived
   from it.
4. **Stack env**: reference `config.sops.placeholder.<service>ClientSecret`
   in a sops template in the service's stack. Issuer is
   `https://auth.peeraten.net`.
5. Rebuild **prime** (it collects `oidc-config` from all hosts) together with
   the service host — the client must exist before the service redirects to
   it.

### Gotchas

- Some apps read claims from the ID token instead of userinfo (not
  OIDC-conformant). Symptom: "provider didn't provide an email/groups". Fix
  with a claims policy, e.g.
  `claims_policies.<name>.id_token = [ "email" ];` + `claims_policy = "<name>"`
  on the client (karakeep needs this).
- Existing local accounts usually link by **matching email** (immich, karakeep
  via `OAUTH_ALLOW_DANGEROUS_EMAIL_ACCOUNT_LINKING`). Paperless/allauth does
  NOT auto-link — first OIDC login creates a fresh user; transfer ownership or
  pre-link via profile.
- Redirect URIs, auth method, and PKCE differ per app — always copy from the
  authelia integration guide instead of guessing.
- Existing clients: immich, paperless, karakeep, chatto, jellyfin
  (jellyfin uses the SSO-Auth plugin, ro-mounted from
  `packages/jellyfin-sso-plugin.nix` with a sops-templated XML config over
  `/config/plugins/configurations/SSO-Auth.xml`).

## Quadlet Configuration Best Practices

### Key Notes

- **Quadlet Service Names**: Quadlet units are just the container name with
  `.service` suffix, NOT prefixed with `quadlet-`. For container `service-main`,
  the systemd service is `service-main.service`.

### File Structure Pattern

All quadlet configurations follow this standardized structure using the stack
module. Comments are for clarification only:

```nix
# modules/aspects/services/service-name.nix
{ den, ... }:
{
  den.aspects.services.service-name = {
    nixos =
      { config, ... }:
      let
        my = config.services.my.service-name;
      in
      {
        # sops secrets — always one value per secret
        sops.secrets = {
          serviceSecret = { };
        };

        # template file (if secrets needed)
        # restartUnits use plain "<name>.service" strings — the prefixed container name
        sops.templates."service.env" = {
          restartUnits = [
            "service-name-main.service"
            "service-name-db.service"
          ];
          content = ''
            SECRET_KEY=${config.sops.placeholder.serviceSecret}
          '';
        };

        services.my.service-name = {
          port = 3000;
          # .lab for local-only, peeraten.net for public via prime's caddy
          domain = "service-name.lab.keyruu.de";
          proxy = {
            enable = true;
            whitelist.enable = true;
          };
          # backup paths and systemd units are auto-wired from stack config
          backup.enable = true;
          stack = {
            enable = true;
            directories = [ "data" "config" ];
            # only for multi-container stacks that need inter-container communication
            network.enable = true;
            # OWASP security hardening for all containers
            security.enable = true;

            # containers use short names, auto-prefixed to service-name-main etc.
            containers = {
              main = {
                containerConfig = {
                  # never use latest, always versioned tags
                  image = "service:v0.1.0";
                  # publish ports manually for the main service
                  publishPorts = [ "127.0.0.1:${toString my.port}:3000" ];
                  volumes = [
                    "${my.stack.path}/data:/data"
                    "${my.stack.path}/config:/config"
                  ];
                  # non-secret env vars
                  environments = {
                    KEY = "value";
                    # inter-container hostnames are the network aliases
                    DB_HOST = "service-name-db";
                  };
                  environmentFiles = [ config.sops.templates."service.env".path ];
                  # network is auto-wired by stack.network, just set aliases
                  networkAliases = [ "service-main" ];
                };
                # use dependsOn with short sibling names instead of manual After/Requires
                dependsOn = [ "db" ];
              };

              db = {
                containerConfig = {
                  image = "postgres:16";
                  volumes = [ "${my.stack.path}/db:/var/lib/postgresql/data" ];
                  networkAliases = [ "db" ];
                };
              };
            };
          };
        };
      };
  };
}
```

For services proxied for the public: set `proxy.public = true` (requires
`proxy.server = "nginx"`) — the service's nginx handles mesh-internal routing,
prime's caddy fronts it for the public internet via the public-proxy quirk.
Host-networking services (e.g. home-assistant) define their container in
`virtualisation.quadlet.containers` directly, not in `stack.containers`, since
they cannot use stack network auto-wiring.

### Converting Docker Compose to Quadlet

#### 1. Analyze the Docker Compose

- Identify all services and their dependencies
- Note volume mounts, environment variables, and networks
- Check for secrets or sensitive data

#### 2. Create the Stack Module

```nix
# inside den.aspects.services.service-name.nixos = { config, ... }: { ... }
services.my.service-name = {
  port = 3000;
  domain = "service-name.lab.keyruu.de";
  proxy.enable = true;
  backup.enable = true;
  stack = {
    enable = true;
    directories = [ "data" "config" ];
    network.enable = true;  # only for multi-container stacks
    security.enable = true;

    containers = {
      # containers defined here with short names
      # publish ports manually on the main container
    };
  };
};
```

#### 3. Handle Secrets

```nix
# inside the service aspect's nixos block
{
  # Declare secrets (no restartUnits needed on individual secrets)
  sops.secrets = {
    serviceSecret = { };
  };

  # Create environment template with restart units
  # restartUnits use plain "<name>.service" strings — the prefixed container name
  sops.templates."service.env" = {
    restartUnits = [ "service-name-main.service" ];
    content = ''
      SECRET=${config.sops.placeholder.serviceSecret}
    '';
  };

  # For multiple containers:
  sops.templates."service.env" = {
    restartUnits = [
      "service-name-main.service"
      "service-name-db.service"
    ];
    content = ''
      SECRET=${config.sops.placeholder.serviceSecret}
    '';
  };
}
```

#### 4. Convert Services

Docker Compose services become stack containers with short names:

```nix
stack.containers = {
  main = {
    containerConfig = {
      image = "image:tag";
      publishPorts = [ "127.0.0.1:${toString my.port}:3000" ];
      volumes = [ "${my.stack.path}/data:/container/path" ];
      environments = { ENV_VAR = "value"; };
      environmentFiles = [ config.sops.templates."service.env".path ];
      networkAliases = [ "service-main" ];
    };
    # use dependsOn instead of manual After/Requires
    dependsOn = [ "db" ];
  };

  db = {
    containerConfig = {
      image = "postgres:16";
      volumes = [ "${my.stack.path}/db:/var/lib/postgresql/data" ];
      networkAliases = [ "db" ];
    };
  };
};
```

### Key Patterns

#### Port Binding

- Publish ports manually on the main container using `publishPorts = [ "127.0.0.1:${toString my.port}:<internalPort>" ]`
- `my.port` is the port defined in `services.my.<name>.port`
- External access goes through nginx reverse proxy

#### Volume Mounts

- Use `${my.stack.path}/subdir:/container/path` pattern
- Directories are created via `stack.directories`
- When `stack.user` is enabled, directories default to user ownership with
  `0750`
- For custom permissions, use attrset form:
  `{ path = "db"; mode = "0770"; owner = "root"; group = "root"; }`

#### Service Dependencies

- Use `dependsOn = [ "db" ]` with short sibling names for intra-stack deps
- The stack auto-generates both `After` and `Requires`
- For dependencies on containers outside the stack, use `unitConfig.After` /
  `unitConfig.Requires` with full `.ref` strings directly

#### Network Configuration

- For single-container stacks, omit `network.enable` — containers use the
  default bridge network
- For multi-container stacks, set `network.enable = true` — all stack containers
  get the network auto-wired
- Add `networkAliases` for services that other containers need to reach
- Use the service name as alias for consistency

#### Backup Configuration

Backup paths and systemd units are auto-wired by the stack module when
`backup.enable = true`. No manual configuration needed for standard stacks.

For custom backup paths, override with:

```nix
backup = {
  enable = true;
  paths = [ "/custom/path" ];
};
```

#### Environment Variables

- Put non-sensitive vars in `environments`
- Put sensitive vars in sops templates and use `environmentFiles`
- Use consistent naming patterns

#### Configuration Files and Restart Triggers

For services that need configuration files, use `X-RestartTrigger` to restart
containers when config files change:

```nix
# Create config file
environment.etc."stacks/service-name/config/config.yml".text = # yaml
  ''
    # Service configuration
    port: 8080
    database: ${config.sops.placeholder.dbUrl}
  '';

# On the stack container:
stack.containers.main = {
  containerConfig = {
    volumes = [ "${my.stack.path}/config:/config" ];
  };
  unitConfig = {
    # Restart when config file changes
    "X-RestartTrigger" = [
      config.environment.etc."stacks/service-name/config.yml".source
    ];
  };
};
```

#### Automatic Restarts with SOPS

Always include `restartUnits` for templates to ensure containers restart when
secrets change. Use plain `"<container>.service"` strings with the full
prefixed container name (e.g. `"karakeep-web.service"`, not `"web.service"`).

**Best Practice**: Only add `restartUnits` to the SOPS template, not individual
secrets. The template will automatically trigger when any referenced secret
changes, eliminating redundancy.

```nix
# inside the service aspect's nixos block
{
  sops.secrets = {
    serviceSecret = { };
    anotherSecret = { };
  };

  # For single container — use full prefixed name
  sops.templates."service.env" = {
    restartUnits = [ "service-name-main.service" ];
    content = ''
      SECRET=${config.sops.placeholder.serviceSecret}
    '';
  };

  # For multiple containers
  sops.templates."service.env" = {
    restartUnits = [
      "service-name-main.service"
      "service-name-db.service"
    ];
    content = ''
      SECRET=${config.sops.placeholder.serviceSecret}
      ANOTHER=${config.sops.placeholder.anotherSecret}
    '';
  };
}
```

#### Health Checks

Use the proper Quadlet health check options instead of Docker Compose style
healthcheck blocks:

```nix
stack.containers.main = {
  containerConfig = {
    healthCmd = "wget --no-verbose --tries=1 --spider http://localhost:8080/health";
    healthInterval = "30s";
    healthTimeout = "10s";
    healthRetries = 3;
    healthStartPeriod = "30s";
  };
};
```

Available health check options:

- `healthCmd` - Command to run for health check
- `healthInterval` - How often to run health check
- `healthTimeout` - Maximum time for health check command
- `healthRetries` - Number of consecutive failures needed to mark unhealthy
- `healthStartPeriod` - Grace period before health checks count toward retry
  count
- `healthOnFailure` - Action to take on health check failure (e.g., "kill",
  "restart")

#### Security Hardening Overrides

With `stack.security.enable = true`, only override what the container actually
needs — most defaults survive more than expected:

- **`readOnlyRootFilesystem` only blocks unmounted paths.** Volumes stay
  writable, and podman `--read-only` still tmpfs-mounts `/run`, `/tmp`,
  `/var/tmp`. Containers that write only to volumes/tmpfs (redis with `/data`
  volume, postgres with data volume + `/var/run/postgresql`) work fine with
  readOnly on. Only set `readOnlyRootFilesystem = false` when the container
  writes elsewhere — check the image entrypoint (e.g. dawarich writes
  `/var/app/{tmp,log}`, Rails apps generally write app-dir `tmp/` and `log/`).
- **`dropAllCapabilities` needs `addCapabilities` for root-dropping
  entrypoints.** Official postgres/redis images start as root and drop to
  their service user: postgres needs
  `[ "CHOWN" "FOWNER" "DAC_OVERRIDE" "SETUID" "SETGID" ]`, redis (su-exec)
  needs `[ "DAC_OVERRIDE" "SETUID" "SETGID" "SETPCAP" ]`.
- **`noNewPrivileges = true` does NOT break privilege _drops_.** su-exec/gosu
  dropping from root works under NNP given SETUID/SETGID caps — NNP only
  blocks privilege _escalation_ (setuid binaries, file caps). Don't disable it
  for postgres/redis-style entrypoints.
- **Resource limits**: `security.memoryLimit` per container maps to quadlet
  `memory`. There is no native quadlet CPU option — use
  `containerConfig.podmanArgs = [ "--cpus=0.5" ]`.

#### Secret Naming

Use camelCase for SOPS secret names for consistency:

```nix
# Preferred camelCase naming
sops.secrets = {
  serviceAuthSecret = { };
  databasePassword = { };
  apiKey = { };
};
```

### Common Gotchas

- **Never search `/nix/store`** with `find`, `ls`, `grep`, `rg`, or anything
  recursive. The store has tens of thousands of paths and scans take forever.
  Use `nix path-info`, `nix eval`, or open the specific source file directly.
  If you must look in the store, target a known path
  (`/nix/store/<hash>-<name>`) — never `find /nix/store` or `rg /nix/store`.
- Public peeraten.net domains: set `services.my.<name>.proxy.public = true`
  (requires `proxy.server = "nginx"`) — prime's caddy fronts it via the
  public-proxy quirk, no external proxy config needed
- Use `exec` instead of `command` for container arguments
- Container short names in `stack.containers` are auto-prefixed with the stack
  name (e.g. `web` → `karakeep-web`) — except single-container stacks, which
  keep the short name as-is; name that container after the stack
- For SOPS `restartUnits` and inter-container hostnames, always use the full
  prefixed container name (e.g. `"karakeep-web.service"`, not
  `"web.service"`)
- Don't create networks for single-container stacks — use default bridge network
  instead
- Only add `restartUnits` to SOPS templates, not individual secrets (templates
  trigger when any referenced secret changes)
- Use `X-RestartTrigger` for configuration files that should restart containers
  when changed
- Use `dependsOn = [ "db" ]` for intra-stack deps instead of manual
  `unitConfig.After/Requires`
- Use proper Quadlet health check options (`healthCmd`, `healthInterval`, etc.)
  instead of Docker Compose style `healthcheck` blocks
- Use camelCase for SOPS secret names for consistency
- `serviceConfig.Restart = "always"` is already the quadlet-nix default — never
  set it explicitly
- Per-container security overrides use `security.*` directly on the container
  (null = use stack global)
