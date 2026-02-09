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

## Quadlet Configuration Best Practices

### Key Notes

- **Quadlet Service Names**: Quadlet units are just the container name with
  `.service` suffix, NOT prefixed with `quadlet-`. For container `service-main`,
  the systemd service is `service-main.service`.

### File Structure Pattern

All quadlet configurations follow this standardized structure, but do ignore the
comments, these are just for clarification:

```nix
{ config, ... }:
let
  stackPath = "/etc/stacks/service-name";
  my = config.services.my.service-name;
in
{
  # sops secrets these are always just one value, if there multiple values like user and password, you need to create two secrets
  sops.secrets = {
    serviceSecret = {
      # if there is a template you wont need to restart the unit here as well
      restartUnits = [ "service-main.service" ];
    };
  };

  # directory creation
  systemd.tmpfiles.rules = [
    "d ${stackPath}/data 0755 root root"
    "d ${stackPath}/config 0755 root root"
  ];

  # template file (if secrets needed), this can either be a env file that can be used in environmentFiles or a general config file like yaml or toml, which then can be mounted into the container
  sops.templates."service.env" = {
    restartUnits = [ "service-main.service" ];
    content = ''
      SECRET_KEY=${config.sops.placeholder.serviceSecret}
    '';
  };

  services.my.service-name = {
    port = 3000;
    # if the service is only used locally and not proxied through a vps then .lab is fine
    domain = "service-name.lab.keyruu.de";
    proxy = {
      enable = true;
      whitelist.enable = true;
    };
    backup = {
      enable = true;
      paths = [ stackPath ];
      # this is not needed if there is only one container and it has the same name as in services.my
      systemd.unit = "service-name-*";
    };
  };
  # here is definition for a service that is proxied for the public
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
      backup = {
        enable = true;
        paths = [ stackPath ];
      };
    };


  # quadlet configuration
  virtualisation.quadlet =
    let
      # this is only needed if the app contains multiple containers that need to talk to eachother
      inherit (config.virtualisation.quadlet) networks;
    in
    {
      # this is only needed if the app contains multiple containers that need to talk to eachother
      networks.service-name.networkConfig = {
        driver = "bridge";
        podmanArgs = [ "--interface-name=service-name" ];
      };
      
      containers = {
        service-name-main = {
          containerConfig = {
            # never use latest here, we always want versioned tags
            image = "service:v0.1.0";
            # my.port should only be used for the first port and the second one should be the one thats used in the docker image
            # this is bc the ports on the host can be different than the internal one bc of conflicts
            publishPorts = [ "127.0.0.1:${toString my.port}:PORT" ];
            volumes = [ 
              "${stackPath}/data:/data"
              "${stackPath}/config:/config"
            ];
            # these can be used for env vars that arent secrets
            environments = { KEY = "value"; };
            environmentFiles = [ config.sops.templates."service.env".path ];
            # this is only needed if the app contains multiple containers that need to talk to eachother
            networks = [ networks.service-name.ref ];
            networkAliases = [ "service-alias" ];
          };
          serviceConfig = {
            # this should be either always or on-failure
            Restart = "always";
          };
          # this can be used for dependencies on other containers
          unitConfig = {
            After = [ "dependency.service" ];
            Requires = [ "dependency.service" ];
          };
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

```bash
# Use /etc/stacks/service-name/ pattern
systemd.tmpfiles.rules = [
  "d ${stackPath}/data 0755 root root"
  "d ${stackPath}/config 0755 root root"
];
```

#### 3. Handle Secrets

```nix
# Declare secrets with restart units
sops.secrets = {
  serviceSecret = {
    restartUnits = [ "service-main.service" ];
  };
};

# Create environment template with restart units
sops.templates."service.env" = {
  restartUnits = [ "service-main.service" ];
  content = ''
    SECRET=${config.sops.placeholder.serviceSecret}
  '';
};
```

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
    labels = [
      "wud.tag.include=^\\d+\\.\\d+\\.\\d+$"  # WUD update monitoring
    ];
    networks = [ networks.service-network.ref ];
    networkAliases = [ "service-alias" ];  # For inter-service communication
  };
  serviceConfig = {
    Restart = "always";
  };
  unitConfig = {
    After = [ "dependency.service" ];
    Requires = [ "dependency.service" ];
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

- Use `${stackPath}/subdir:/container/path` pattern
- Create directories with tmpfiles.rules
- Use appropriate permissions (0755 for root, 0770 for specific users)

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

Always include `restartUnits` for both secrets and templates to ensure
containers restart when secrets change. **Important**: Use the exact container
name with `.service` suffix - no `quadlet-` prefix.

**Best Practice**: Only add `restartUnits` to the SOPS template, not individual
secrets. The template will automatically trigger when any referenced secret
changes, eliminating redundancy.

```nix
# Secrets don't need individual restartUnits
sops.secrets = {
  serviceSecret = { };
  anotherSecret = { };
};

# Only the template needs restartUnits
sops.templates."service.env" = {
  restartUnits = [ "service-main.service" ];  # Container name + .service
  content = ''
    SECRET=${config.sops.placeholder.serviceSecret}
    ANOTHER=${config.sops.placeholder.anotherSecret}
  '';
};
```

#### Health Checks

Use the proper Quadlet health check options instead of Docker Compose style
healthcheck blocks:

```nix
# ✅ Correct Quadlet health check format
containers.service-main = {
  containerConfig = {
    healthCmd = "wget --no-verbose --tries=1 --spider http://localhost:8080/health";
    healthInterval = "30s";
    healthTimeout = "10s";
    healthRetries = 3;
    healthStartPeriod = "30s";
  };
};

# ❌ Don't use Docker Compose style
containers.service-main = {
  containerConfig = {
    healthcheck = {
      test = [ "CMD" "wget" "--spider" "http://localhost:8080/health" ];
      interval = "30s";
      timeout = "10s";
      retries = 3;
      startPeriod = "30s";
    };
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
# ✅ Preferred camelCase naming
sops.secrets = {
  serviceAuthSecret = { };
  databasePassword = { };
  apiKey = { };
};

# ❌ Avoid kebab-case 
sops.secrets = {
  service-auth-secret = { };
  database-password = { };
  api-key = { };
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
- Add WUD labels only to main application containers for update monitoring
- Only add `restartUnits` to SOPS templates, not individual secrets (templates
  trigger when any referenced secret changes)
- Use `X-RestartTrigger` for configuration files that should restart containers
  when changed
- **Critical**: Quadlet service names are just the container name + `.service` -
  NO `quadlet-` prefix!
- Use proper Quadlet health check options (`healthCmd`, `healthInterval`, etc.)
  instead of Docker Compose style `healthcheck` blocks
- Use camelCase for SOPS secret names for consistency
