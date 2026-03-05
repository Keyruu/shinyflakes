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
| `quadlet.toService` | container | systemd service name | `"karakeep-web.service"` |
| `quadlet.name` | container | plain container name | `"karakeep-web"` |
| `quadlet.alias` | container | first network alias | `"meilisearch"` |

**IMPORTANT**: `flake.lib.quadletToService` is a legacy alias. All new code must
use `quadlet.service`. See `MIGRATE_STACKS.md` for migration instructions.

## Stack Module (`services.my.<name>.stack`)

The stack module (`nix/modules/services/my/stack.nix`) reduces boilerplate for
quadlet container stacks by auto-generating tmpfiles, users, networks, backup
wiring, and OWASP security hardening.

### What the Stack Module Auto-Generates

When `stack.enable = true`:

- **Directories**: `stack.directories` entries become `systemd.tmpfiles.rules`.
  When `stack.user` is enabled, directories default to user ownership with mode
  `0750`.
- **Users/Groups**: `stack.user` creates `users.users` and `users.groups`.
- **Network**: `stack.network` creates a quadlet bridge network with
  `interfaceName`. The network is auto-wired into all member containers.
- **Backup**: When `backup.enable = true`, `backup.paths` defaults to
  `[ stack.path ]` and `backup.systemd.unit` is auto-wired from
  `stack.containers.members`.
- **Security**: When `stack.containers.security.enable = true`, OWASP hardening
  is applied to all member containers (except those in `security.exclude`). All
  values use `mkDefault` so per-container overrides always win.

**Note**: `serviceConfig.Restart = "always"` is already the default in
quadlet-nix, so stacks never need to set it.

### Stack Options Quick Reference

- `stack.enable` — enable stack infrastructure
- `stack.path` — base path (default: `/etc/stacks/<name>`), usable as
  `my.stack.path`
- `stack.directories` — list of subdirs (string or `{ path; mode; owner; group; }`)
- `stack.user.{ enable, name, uid, group, gid, extraGroups }` — system user
- `stack.network.{ enable, name }` — bridge network
- `stack.containers.members` — list of container attrsets (NOT `.ref` strings)
- `stack.containers.security.{ enable, exclude, dropAllCapabilities,
  noNewPrivileges, readOnlyRootFilesystem, memoryLimit, pidsLimit }`

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
  inherit (config.virtualisation.quadlet) containers;
  inherit (flake.lib) quadlet;
in
{
  # sops secrets — always one value per secret
  sops.secrets = {
    serviceSecret = { };
  };

  # template file (if secrets needed)
  # For single container: restartUnits = [ (quadlet.toService containers.service-name) ];
  # For multiple containers: restartUnits = map quadlet.toService [ containers.service-main containers.service-db ];
  sops.templates."service.env" = {
    restartUnits = map quadlet.toService [
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
      # pass container attrsets directly, use `with containers;` for brevity
      containers = with containers; {
        members = [
          service-name-main
          service-name-db
        ];
        security.enable = true;
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
        # home-assistant uses host networking, no bridge network or members needed
      };
    };

  # quadlet containers — only container-specific config, no network/restart boilerplate
  virtualisation.quadlet.containers = {
    service-name-main = {
      containerConfig = {
        # never use latest, always versioned tags
        image = "service:v0.1.0";
        # my.port for the host port, second value is the container-internal port
        publishPorts = [ "127.0.0.1:${toString my.port}:PORT" ];
        volumes = [
          "${my.stack.path}/data:/data"
          "${my.stack.path}/config:/config"
        ];
        # non-secret env vars
        environments = {
          KEY = "value";
          # use quadlet.alias for inter-container hostnames
          DB_HOST = quadlet.alias containers.service-name-db;
        };
        environmentFiles = [ config.sops.templates."service.env".path ];
        # network is auto-wired by stack.network, just set aliases
        networkAliases = [ "service-main" ];
      };
      # dependencies on other containers
      unitConfig = {
        After = [ containers.service-name-db.ref ];
        Requires = [ containers.service-name-db.ref ];
      };
    };

    service-name-db = {
      containerConfig = {
        image = "postgres:16";
        volumes = [ "${my.stack.path}/db:/var/lib/postgresql/data" ];
        networkAliases = [ "db" ];
      };
    };
  };
}
```

### Converting Docker Compose to Quadlet

#### 1. Analyze the Docker Compose

- Identify all services and their dependencies
- Note volume mounts, environment variables, and networks
- Check for secrets or sensitive data

#### 2. Create Directory Structure

```nix
# Use /etc/stacks/service-name/ pattern
systemd.tmpfiles.rules = [
  "d ${stackPath}/data 0755 root root"
  "d ${stackPath}/config 0755 root root"
];
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

  # Create environment template with restart units using quadlet
  # For single container:
  sops.templates."service.env" = {
    restartUnits = [ (quadlet.service containers.service-name) ];
    content = ''
      SECRET=${config.sops.placeholder.serviceSecret}
    '';
  };

  # For multiple containers:
  sops.templates."service.env" = {
    restartUnits = map quadlet.service [
      containers.service-main
      containers.service-db
    ];
    content = ''
      SECRET=${config.sops.placeholder.serviceSecret}
    '';
  };
}
```

Note: For quadlet internal references (like `unitConfig.After/Requires`), use `containers.name.ref` directly.
For external systemd units (like `restartUnits`), use `flake.lib.quadlet` to convert container refs to service names.

#### 4. Convert Services

```nix
# Docker Compose service becomes:
containers.service-name = {
  containerConfig = {
    image = "image:tag";
    publishPorts = [ "127.0.0.1:${toString my.port}:port" ];  # Bind to localhost
    volumes = [ "${stackPath}/data:/container/path" ];
    environments = { ENV_VAR = "value"; };
    environmentFiles = [ config.sops.templates."service.env".path ];
    networks = [ networks.service-network.ref ];
    networkAliases = [ "service-alias" ];  # For inter-service communication
  };
  serviceConfig = {
    Restart = "always";
  };
  # Use containers.name.ref for internal quadlet references
  unitConfig = {
    After = [ containers.dependency.ref ];
    Requires = [ containers.dependency.ref ];
  };
};
```

#### 5. Network Configuration

```nix
# Create dedicated network with interface name if there is more than one container
networks.service-network.networkConfig = {
  driver = "bridge";
  podmanArgs = [ "--interface-name=service-name" ];
};

# Reference in containers
networks = [ networks.service-network.ref ];
```

### Key Patterns

#### Port Binding

- Always bind to `127.0.0.1:PORT:PORT` for security
- Use different ports for each service to avoid conflicts
- External access goes through nginx reverse proxy

#### Volume Mounts

- Use `${my.stack.path}/subdir:/container/path` pattern
- Directories are created via `stack.directories`
- When `stack.user` is enabled, directories default to user ownership with
  `0750`
- For custom permissions, use attrset form:
  `{ path = "db"; mode = "0770"; owner = "root"; group = "root"; }`

#### Service Dependencies

- Use `After` for startup order
- Use `Requires` for hard dependencies
- Use `Wants` for soft dependencies

#### Network Configuration

- For single-container stacks, omit network configuration entirely - containers
  will use the default bridge network
- Only create dedicated networks for multi-container stacks that need
  inter-service communication
- Add `networkAliases` for services that other containers need to reach
- Use the service name as alias for consistency

#### Backup Configuration

The `backup.systemd.unit` option accepts both a string or a list of service names.
Use `quadlet.service` to convert container refs:

```nix
# For single container
services.my.service-name = {
  backup = {
    enable = true;
    paths = [ stackPath ];
    systemd.unit = [ (quadlet.service containers.service-name) ];
  };
};

# For multiple containers
services.my.service-name = {
  backup = {
    enable = true;
    paths = [ stackPath ];
    systemd.unit = map quadlet.service [
      containers.service-main
      containers.service-db
    ];
  };
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

# Container with restart trigger
containers.service-main = {
  containerConfig = {
    volumes = [ "${stackPath}/config:/config" ];
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
secrets change. Use `flake.lib.quadlet` to convert container refs to
systemd service names.

**Best Practice**: Only add `restartUnits` to the SOPS template, not individual
secrets. The template will automatically trigger when any referenced secret
changes, eliminating redundancy.

```nix
# In your stack file, import containers and quadlet
{ config, flake, ... }:
let
  inherit (config.virtualisation.quadlet) containers;
  inherit (flake.lib) quadlet;
in
{
  # Secrets don't need individual restartUnits
  sops.secrets = {
    serviceSecret = { };
    anotherSecret = { };
  };

  # For single container - use list with single element
  sops.templates."service.env" = {
    restartUnits = [ (quadlet.service containers.service-name) ];
    content = ''
      SECRET=${config.sops.placeholder.serviceSecret}
    '';
  };

  # For multiple containers - use map pattern
  sops.templates."service.env" = {
    restartUnits = map quadlet.service [
      containers.service-main
      containers.service-db
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
containers.service-main = {
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
- Network references must use `networks.name.ref` pattern
- Always include `inherit (config.virtualisation.quadlet) networks;` in let
  block when using networks
- Don't create networks for single-container stacks - use default bridge network
  instead
- Only add `restartUnits` to SOPS templates, not individual secrets (templates
  trigger when any referenced secret changes)
- Use `X-RestartTrigger` for configuration files that should restart containers
  when changed
- **Container References**:
  - For internal quadlet dependencies (After/Requires): use `containers.name.ref`
  - For external systemd units (restartUnits, backup commands): use `quadlet.service containers.name`
  - Single container: `restartUnits = [ (quadlet.service containers.name) ];`
  - Multiple containers: `restartUnits = map quadlet.service [ containers.name1 containers.name2 ];`
- Use proper Quadlet health check options (`healthCmd`, `healthInterval`, etc.)
  instead of Docker Compose style `healthcheck` blocks
- Use camelCase for SOPS secret names for consistency
- Always import `containers` from `config.virtualisation.quadlet` and `quadlet` from `flake.lib` in the let block
