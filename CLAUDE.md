# Shinyflakes Instructions

## Project Structure

This project uses [blueprint](https://github.com/numtide/blueprint) for
convention-based flake structure. Blueprint automatically discovers and exposes
Nix configurations based on folder structure, eliminating the need to manually
maintain flake outputs.

### Folder Structure

```
nix/
├── hosts/              # Host configurations (auto-discovered)
│   ├── mentat/        # NixOS host
│   │   ├── configuration.nix  # → nixosConfigurations.mentat
│   │   ├── hardware-configuration.nix
│   │   └── modules/   # Host-specific modules
│   │       ├── stacks/      # Quadlet container definitions
│   │       ├── default.nix  # Imports all host modules
│   │       └── *.nix
│   ├── prime/         # NixOS host
│   ├── carryall/      # NixOS host (laptop)
│   └── thopter/       # NixOS host (laptop)
├── modules/           # Shared modules (auto-discovered)
│   ├── nixos/        # NixOS modules
│   │   ├── core.nix
│   │   ├── workstation.nix
│   │   └── *.nix
│   ├── home/         # Home Manager modules
│   │   ├── linux/
│   │   └── programs/
│   └── services/     # Service-specific modules
├── packages/         # Custom packages (auto-discovered)
│   └── *.nix        # → packages.<name>
└── secrets.yaml     # SOPS encrypted secrets
```

### How Blueprint Works

In `flake.nix`:

```nix
outputs = inputs: inputs.blueprint {
  inherit inputs;
  prefix = "nix";  # All Nix code lives in nix/ folder
};
```

Blueprint automatically:

- Creates `nixosConfigurations.<hostname>` from `nix/hosts/*/configuration.nix`
- Exposes `nixosModules.<name>` from `nix/modules/nixos/*.nix`
- Exposes `homeModules.<name>` from `nix/modules/home/*.nix`
- Creates `packages.<system>.<name>` from `nix/packages/*.nix`

### Building and Deploying

**Build a NixOS configuration:**

```bash
# Build without switching
nixos-rebuild build --flake .#hostname

# Build and switch
sudo nixos-rebuild switch --flake .#hostname

# Build and test (reverts on reboot)
sudo nixos-rebuild test --flake .#hostname
```

### Adding a New Host

1. Create `nix/hosts/<hostname>/configuration.nix`:

```nix
{ inputs, flake, config, pkgs, lib, ... }:
{
  imports = [
    inputs.sops-nix.nixosModules.sops
    flake.modules.nixos.core  # Shared core config
    ./hardware-configuration.nix
    ./modules  # Host-specific modules
  ];

  networking.hostName = "hostname";
  user.name = "username";

  nixpkgs.hostPlatform = "x86_64-linux";
  system.stateVersion = "24.11";
}
```

2. Generate hardware configuration:

```bash
nixos-generate-config --root /mnt --show-hardware-config > nix/hosts/<hostname>/hardware-configuration.nix
```

3. Create `nix/hosts/<hostname>/modules/default.nix` to import host-specific
   modules:

```nix
{ ... }:
{
  imports = [
    ./nginx.nix
    ./stacks
  ];
}
```

4. Blueprint automatically discovers it - just build!

### Project Conventions

- **Host-specific modules** go in `nix/hosts/<hostname>/modules/`
- **Shared modules** go in `nix/modules/nixos/` or `nix/modules/home/`
- **Container stacks** go in `nix/hosts/<hostname>/modules/stacks/`
- **Secrets** are in `nix/secrets.yaml` and managed with SOPS
- **Custom packages** go in `nix/packages/`
- Use `flake.modules.nixos.<name>` to reference shared NixOS modules
- Use `flake.modules.home.<name>` to reference shared Home Manager modules

## Quadlet Helper Library (`flake.lib.quadlet`)

The `flake.lib.quadlet` attrset provides helpers for working with quadlet
containers. Always use `inherit (flake.lib) quadlet;` in the let block.

| Function | Input | Output | Example |
|---|---|---|---|
| `quadlet.service` | container | systemd service name | `"karakeep-web.service"` |
| `quadlet.name` | container | plain container name | `"karakeep-web"` |
| `quadlet.alias` | container | first network alias | `"meilisearch"` |

These helpers work with containers from `config.virtualisation.quadlet.containers`,
which is where stack-defined containers end up after auto-prefixing.

## Stack Module (`services.my.<name>.stack`)

The stack module (`nix/modules/services/my/stack.nix`) reduces boilerplate for
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
- `stack.containers` — attrsOf container submodules (short names, auto-prefixed)
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

### Infrastructure (defined in `nix/hosts/mentat/modules/nas.nix`)

- `zfs-encrypted.target` — systemd target representing "datasets are unlocked"
- `zfs-encrypted-check.service` — oneshot gate that verifies `keystatus =
  available` before the target can activate
- `zfs-unlock` — shell script package (`nix/packages/zfs-unlock.nix`) that runs
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

## Quadlet Configuration Best Practices

### Key Notes

- **Quadlet Service Names**: Quadlet units are just the container name with
  `.service` suffix, NOT prefixed with `quadlet-`. For container `service-main`,
  the systemd service is `service-main.service`.

### File Structure Pattern

All quadlet configurations follow this standardized structure using the stack
module. Comments are for clarification only:

```nix
{ config, flake, ... }:
let
  my = config.services.my.service-name;
  # containers is needed for SOPS restartUnits and quadlet.alias references
  inherit (config.virtualisation.quadlet) containers;
  inherit (flake.lib) quadlet;
in
{
  # sops secrets — always one value per secret
  sops.secrets = {
    serviceSecret = { };
  };

  # template file (if secrets needed)
  # Reference containers by their full prefixed name from config.virtualisation.quadlet.containers
  sops.templates."service.env" = {
    restartUnits = map quadlet.service [
      containers.service-name-main
      containers.service-name-db
    ];
    content = ''
      SECRET_KEY=${config.sops.placeholder.serviceSecret}
    '';
  };

  services.my.service-name = {
    port = 3000;
    # .lab for local-only, peeraten.net for public via VPS proxy
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
              # use quadlet.alias with full prefixed name for inter-container hostnames
              DB_HOST = quadlet.alias containers.service-name-db;
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

  # here is a definition for a service that is proxied for the public
  services.my.home-assistant =
    let
      domain = "hass.peeraten.net";
    in
    {
      port = 8123;
      inherit domain;
      proxy = {
        enable = true;
        cert = {
          provided = false;
          host = domain;
        };
      };
      backup.enable = true;
      stack = {
        enable = true;
        directories = [ "config" ];
        # home-assistant uses host networking — define the container in
        # virtualisation.quadlet.containers directly (not in stack.containers)
        # since it cannot use stack network auto-wiring
      };
    };
}
```

### Converting Docker Compose to Quadlet

#### 1. Analyze the Docker Compose

- Identify all services and their dependencies
- Note volume mounts, environment variables, and networks
- Check for secrets or sensitive data

#### 2. Create the Stack Module

```nix
{ config, flake, ... }:
let
  my = config.services.my.service-name;
  inherit (config.virtualisation.quadlet) containers;
  inherit (flake.lib) quadlet;
in
{
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
}
```

#### 3. Handle Secrets

```nix
# In your stack file, import containers and quadlet
{ config, flake, ... }:
let
  inherit (config.virtualisation.quadlet) containers;
  inherit (flake.lib) quadlet;
in
{
  # Declare secrets (no restartUnits needed on individual secrets)
  sops.secrets = {
    serviceSecret = { };
  };

  # Create environment template with restart units
  # Reference full prefixed names from config.virtualisation.quadlet.containers
  sops.templates."service.env" = {
    restartUnits = [ (quadlet.service containers.service-name-main) ];
    content = ''
      SECRET=${config.sops.placeholder.serviceSecret}
    '';
  };

  # For multiple containers:
  sops.templates."service.env" = {
    restartUnits = map quadlet.service [
      containers.service-name-main
      containers.service-name-db
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
secrets change. Reference the full prefixed container names from
`config.virtualisation.quadlet.containers`.

**Best Practice**: Only add `restartUnits` to the SOPS template, not individual
secrets. The template will automatically trigger when any referenced secret
changes, eliminating redundancy.

```nix
{ config, flake, ... }:
let
  inherit (config.virtualisation.quadlet) containers;
  inherit (flake.lib) quadlet;
in
{
  sops.secrets = {
    serviceSecret = { };
    anotherSecret = { };
  };

  # For single container — use full prefixed name
  sops.templates."service.env" = {
    restartUnits = [ (quadlet.service containers.service-name-main) ];
    content = ''
      SECRET=${config.sops.placeholder.serviceSecret}
    '';
  };

  # For multiple containers
  sops.templates."service.env" = {
    restartUnits = map quadlet.service [
      containers.service-name-main
      containers.service-name-db
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

- Remember to add external proxy configuration in sleipnir for peeraten.net
  domains
- Use `exec` instead of `command` for container arguments
- Container short names in `stack.containers` are auto-prefixed with the stack
  name (e.g. `web` → `karakeep-web`)
- For SOPS `restartUnits` and `quadlet.alias`, always use the full prefixed name
  from `config.virtualisation.quadlet.containers` (e.g.
  `containers.karakeep-web`, not `containers.web`)
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
- Always import `containers` from `config.virtualisation.quadlet` and `quadlet`
  from `flake.lib` in the let block
- `serviceConfig.Restart = "always"` is already the quadlet-nix default — never
  set it explicitly
- Per-container security overrides use `security.*` directly on the container
  (null = use stack global)
