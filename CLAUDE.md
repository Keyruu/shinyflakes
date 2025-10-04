# Shinyflakes Instructions

## Quadlet Configuration Best Practices

### Key Notes

- **Quadlet Service Names**: Quadlet units are just the container name with `.service` suffix, NOT prefixed with `quadlet-`. For container `service-main`, the systemd service is `service-main.service`.

### File Structure Pattern

All quadlet configurations follow this standardized structure:

```nix
{ config, ... }:
let
  stackPath = "/etc/stacks/service-name";
in
{
  # 1. Sops secrets (if needed)
  sops.secrets = {
    serviceSecret = {
      restartUnits = [ "service-main.service" ];
    };
  };

  # 2. Directory creation
  systemd.tmpfiles.rules = [
    "d ${stackPath}/data 0755 root root"
    "d ${stackPath}/config 0755 root root"
  ];

  # 3. Environment template (if secrets needed)
  sops.templates."service.env" = {
    restartUnits = [ "service-main.service" ];
    content = ''
      SECRET_KEY=${config.sops.placeholder.serviceSecret}
    '';
  };

  # 4. Quadlet configuration
  virtualisation.quadlet =
    let
      inherit (config.virtualisation.quadlet) networks;
    in
    {
      networks.service-name.networkConfig = {
        driver = "bridge";
        podmanArgs = [ "--interface-name=service-name" ];
      };
      
      containers = {
        service-main = {
          containerConfig = {
            image = "service:latest";
            publishPorts = [ "127.0.0.1:PORT:PORT" ];
            volumes = [ 
              "${stackPath}/data:/data"
              "${stackPath}/config:/config"
            ];
            environments = { KEY = "value"; };
            environmentFiles = [ config.sops.templates."service.env".path ];
            labels = [
              "wud.tag.include=^\\d+\\.\\d+\\.\\d+$"  # For semantic versioning
              # "wud.tag.include=^v\\d+\\.\\d+\\.\\d+$"  # For v-prefixed tags
              # "wud.tag.include=^\\d+\\.\\d+-alpine$"  # For alpine variants
            ];
            networks = [ networks.service-name.ref ];
            networkAliases = [ "service-alias" ];
          };
          serviceConfig = {
            Restart = "always";
          };
          unitConfig = {
            After = [ "dependency.service" ];
            Requires = [ "dependency.service" ];
          };
        };
      };
    };

  # 5. ACME certificate (for external domains)
  security.acme = {
    certs."service.domain.com" = {
      dnsProvider = "cloudflare";
      dnsPropagationCheck = true;
      environmentFile = config.sops.secrets.cloudflare.path;
    };
  };

  # 6. Nginx reverse proxy
  services.nginx.virtualHosts."service.domain.com" = {
    useACMEHost = "service.domain.com";
    forceSSL = true;
    locations."/" = {
      proxyPass = "http://127.0.0.1:PORT";
      proxyWebsockets = true;
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
    publishPorts = [ "127.0.0.1:port:port" ];  # Bind to localhost
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
# Create dedicated network with interface name
networks.service-network.networkConfig = {
  driver = "bridge";
  podmanArgs = [ "--interface-name=service-name" ];
};

# Reference in containers
networks = [ networks.service-network.ref ];
```

#### 6. External Access Setup

For services accessible from outside:

```nix
# Local nginx (on service host)
services.nginx.virtualHosts."service.lab.keyruu.de" = {
  useACMEHost = "lab.keyruu.de";
  forceSSL = true;
  locations."/" = {
    proxyPass = "http://127.0.0.1:PORT";
    proxyWebsockets = true;
  };
};

# External proxy (in sleipnir/proxy.nix for peeraten.net domains)
services.nginx.virtualHosts."service.peeraten.net" = {
  enableACME = true;
  forceSSL = true;
  locations."/" = {
    proxyPass = "http://100.64.0.1:PORT";  # Tailscale IP
    proxyWebsockets = true;
  };
};
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

- For single-container stacks, omit network configuration entirely - containers will use the default bridge network
- Only create dedicated networks for multi-container stacks that need inter-service communication
- Add `networkAliases` for services that other containers need to reach
- Use the service name as alias for consistency

#### Environment Variables

- Put non-sensitive vars in `environments`
- Put sensitive vars in sops templates and use `environmentFiles`
- Use consistent naming patterns

#### Configuration Files and Restart Triggers

For services that need configuration files, use `X-RestartTrigger` to restart containers when config files change:

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

Always include `restartUnits` for both secrets and templates to ensure containers restart when secrets change. **Important**: Use the exact container name with `.service` suffix - no `quadlet-` prefix.

**Best Practice**: Only add `restartUnits` to the SOPS template, not individual secrets. The template will automatically trigger when any referenced secret changes, eliminating redundancy.

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

#### WUD Labels for Update Monitoring

Add appropriate WUD labels to main application containers for automatic update detection:

```nix
labels = [
  "wud.tag.include=^\\d+\\.\\d+\\.\\d+$"      # Standard semantic versioning (1.2.3)
  # "wud.tag.include=^v\\d+\\.\\d+\\.\\d+$"   # v-prefixed tags (v1.2.3)
  # "wud.tag.include=^\\d+\\.\\d+-alpine$"    # Alpine variants (1.2-alpine)
  # "wud.tag.include=^\\d+\\.\\d+\\.\\d+-.*$" # With suffixes (1.2.3-beta)
];
```

Common patterns:

- `^\\d+\\.\\d+\\.\\d+$` - Standard semantic versioning (most common)
- `^v\\d+\\.\\d+\\.\\d+$` - Version tags with 'v' prefix
- `^\\d+\\.\\d+-alpine$` - Alpine-based images
- `^\\d+\\.\\d+\\.\\d+-.*$` - Versions with additional suffixes

Only add labels to the main application containers, not databases or supporting services.

**Disabling WUD for Supporting Services:**

For containers that shouldn't be monitored for updates (databases, caches, etc.), disable WUD monitoring:

```nix
labels = [ "wud.watch=false" ];
```

#### Health Checks

Use the proper Quadlet health check options instead of Docker Compose style healthcheck blocks:

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
- `healthStartPeriod` - Grace period before health checks count toward retry count
- `healthOnFailure` - Action to take on health check failure (e.g., "kill", "restart")

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

- Remember to add external proxy configuration in sleipnir for peeraten.net domains
- Use `exec` instead of `command` for container arguments
- Network references must use `networks.name.ref` pattern
- Always include `inherit (config.virtualisation.quadlet) networks;` in let block when using networks
- Don't create networks for single-container stacks - use default bridge network instead
- Add WUD labels only to main application containers for update monitoring
- Only add `restartUnits` to SOPS templates, not individual secrets (templates trigger when any referenced secret changes)
- Use `X-RestartTrigger` for configuration files that should restart containers when changed
- **Critical**: Quadlet service names are just the container name + `.service` - NO `quadlet-` prefix!
- Use proper Quadlet health check options (`healthCmd`, `healthInterval`, etc.) instead of Docker Compose style `healthcheck` blocks
- Use camelCase for SOPS secret names for consistency

