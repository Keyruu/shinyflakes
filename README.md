<img alt="NixOS" src="https://raw.githubusercontent.com/NixOS/nixos-artwork/master/logo/nix-snowflake-rainbow.svg" width="150px"/>

# Shinyflakes

A comprehensive NixOS and nix-darwin configuration for managing multiple hosts across different platforms. This repository contains declarative configurations for servers, desktops, and development machines using the Nix ecosystem.

## 🏗️ Architecture

This configuration uses a modular approach with:

- **NixOS** for Linux servers and desktops
- **nix-darwin** for macOS development machines  
- **Home Manager** for user-specific configurations
- **SOPS** for secrets management
- **Quadlet** for containerized services via Podman
- **Disko** for declarative disk partitioning

## 🖥️ Hosts

### Linux Servers (NixOS)

- **highwind** - Main homelab server (x86_64-linux)
  - Media services: Jellyfin, Sonarr, Radarr, Lidarr, Bazarr, qBittorrent
  - Home automation: Home Assistant, ESPHome, Zigbee2MQTT, Matter Hub
  - AI services: LibreChat, Whishper, MCP servers
  - Self-hosted apps: Immich, Mealie, Actual Budget, Dawarich, Traccar
  - Monitoring: Grafana, Prometheus, Loki, Beszel
  - Storage: NAS with Samba shares

- **sleipnir** - Hetzner VPS (x86_64-linux)
  - External proxy and reverse proxy services
  - Identity management with Kanidm
  - Rybbit analytics platform
  - Headscale coordination server
  - PostgreSQL database services

- **garm** - Raspberry Pi 3 (aarch64-linux)
  - AdGuard Home for network-wide ad blocking
  - Network services and monitoring

- **thopter** - Lenovo ThinkPad X1 Yoga 7th Gen (x86_64-linux)
  - Mobile workstation with Hyprland desktop
  - Development tools and applications
  - Gaming setup with Steam and Lutris

### macOS (nix-darwin)

- **stern** - Development machine
  - Homebrew integration for macOS-specific apps
  - Development tools and CLI utilities
  - Aerospace window manager

## 🛠️ Key Features

### Container Management

- **Quadlet integration** for systemd-managed containers
- Standardized service deployment patterns
- Automatic container updates with WUD (What's Up Docker)
- Health checks and dependency management

### Security & Secrets

- **SOPS-nix** for encrypted secrets management
- Age-based encryption with multiple keys
- Automatic secret rotation and container restarts
- Secure credential handling for all services

### Networking

- **Tailscale** mesh networking between hosts
- **Nginx** reverse proxy with automatic SSL certificates
- **Cloudflare** DNS and SSL certificate management
- Internal service discovery and load balancing

### Storage & Backup

- **ZFS** for data integrity and snapshots
- **Disko** for declarative disk configuration
- Automated backup strategies
- NAS functionality with Samba

### Monitoring & Observability

- **Grafana** dashboards for system metrics
- **Prometheus** metrics collection
- **Loki** log aggregation
- **Beszel** lightweight monitoring
- Service health monitoring and alerting

## 📁 Repository Structure

```
├── flake.nix              # Main flake configuration
├── hosts/                 # Host-specific configurations
│   ├── highwind/         # Homelab server
│   │   ├── stacks/       # Containerized services
│   │   └── monitoring/   # Monitoring stack
│   ├── sleipnir/         # VPS configuration
│   ├── garm/             # Raspberry Pi
│   ├── thopter/          # Laptop configuration
│   └── stern/            # macOS machine
├── home/                 # Home Manager configurations
│   ├── linux/           # Linux user configs
│   └── mac/             # macOS user configs
├── modules/              # Reusable NixOS modules
├── packages/             # Custom package definitions
├── services/             # Service configurations
└── secrets.yaml         # SOPS encrypted secrets
```

## 🚀 Quick Start

### Prerequisites

- Nix with flakes enabled
- SOPS for secrets management
- Age key for decryption (if using secrets)

### Deployment

For NixOS hosts:

```bash
# Build and switch to new configuration
sudo nixos-rebuild switch --flake .#hostname

# Build without switching (testing)
nixos-rebuild build --flake .#hostname
```

For nix-darwin (macOS):

```bash
# Build and switch
darwin-rebuild switch --flake .#stern
```

### Adding New Services

1. Create service configuration in `hosts/hostname/stacks/`
2. Follow the Quadlet patterns documented in `AGENTS.md`
3. Add secrets to `secrets.yaml` if needed
4. Include in host's `default.nix`

## 🔧 Configuration Highlights

### Service Deployment Pattern

All containerized services follow a standardized pattern:

- Quadlet for container management
- SOPS for secrets
- Nginx reverse proxy
- Health checks and monitoring
- Automatic updates

### Development Environment

- Consistent tooling across all machines
- Shell configurations with Fish
- Editor configurations (Neovim, Helix)
- Development containers and tools

### Desktop Environment (Linux)

- **Hyprland** compositor with custom configurations
- **Stylix** for consistent theming
- Custom keybindings and window management
- Gaming optimizations

## 📚 Documentation

- `AGENTS.md` - Detailed Quadlet configuration patterns and best practices
- `CLAUDE.md` - AI assistant context and instructions
- Individual service documentation in respective directories

## 🔐 Secrets Management

Secrets are managed using SOPS with age encryption:

- Keys stored in `.sops.yaml`
- Encrypted secrets in `secrets.yaml`
- Automatic decryption during deployment
- Service-specific environment files

## 🤝 Contributing

This is a personal configuration repository, but feel free to:

- Use patterns and configurations as inspiration
- Report issues or suggest improvements
- Adapt modules for your own use

## 📄 License

This configuration is provided as-is for educational and reference purposes. Individual components may have their own licenses.
