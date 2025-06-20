# Shinyflakes Instructions

## Quadlet Configuration Best Practices

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
    serviceSecret = { };
  };

  # 2. Directory creation
  systemd.tmpfiles.rules = [
    "d ${stackPath}/data 0755 root root"
    "d ${stackPath}/config 0755 root root"
  ];

  # 3. Environment template (if secrets needed)
  sops.templates."service.env".content = ''
    SECRET_KEY=${config.sops.placeholder.serviceSecret}
  '';

  # 4. Quadlet configuration
  virtualisation.quadlet =
    let
      inherit (config.virtualisation.quadlet) networks;
    in
    {
      networks.service-name.networkConfig.driver = "bridge";
      
      containers = {
        service-main = {
          containerConfig = {
            image = "service:latest";
            publishPorts = [ "127.0.0.1:PORT:PORT" ];
            volumes = [ "${stackPath}/data:/data" ];
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
            Restart = "unless-stopped";
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
# Declare secrets
sops.secrets = {
  serviceSecret = { };
};

# Create environment template
sops.templates."service.env".content = ''
  SECRET=${config.sops.placeholder.serviceSecret}
'';
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
    Restart = "unless-stopped";  # or "always"
  };
  unitConfig = {
    After = [ "dependency.service" ];
    Requires = [ "dependency.service" ];
  };
};
```

#### 5. Network Configuration

```nix
# Create dedicated network
networks.service-network.networkConfig.driver = "bridge";

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

### Common Gotchas

- Remember to add external proxy configuration in sleipnir for peeraten.net domains
- Use `exec` instead of `command` for container arguments
- Network references must use `networks.name.ref` pattern
- Always include `inherit (config.virtualisation.quadlet) networks;` in let block when using networks
- Don't create networks for single-container stacks - use default bridge network instead
- Add WUD labels only to main application containers for update monitoring
