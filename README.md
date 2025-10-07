# Shinyflakes

My personal NixOS/nix-darwin homelab setup. Everything from servers to desktops to my Mac, all defined in one git repo. Because if it's not in git, did it even happen?

## Why Though?

I use NixOS to manage my homelab and it's been pretty awesome having my whole infrastructure version-controlled. No more "it worked on my machine" moments - my machines ARE the configuration.

The secret sauce here is using [Quadlet](https://docs.podman.io/en/latest/markdown/podman-systemd.unit.5.html) (via [quadlet-nix](https://github.com/SEIAROTg/quadlet-nix)) for container management. Why? Because I want proper systemd integration, individual container metrics, and the ability to manage each container separately - not just restart the whole docker-compose when one thing breaks. Plus, Nix lets me do cool stuff like ensuring directories exist before mounting them, templating configs with secrets, and using actual Nix references between resources.

## The Fleet

### mentat - Main homelab server (x86_64-linux)
The big boi running everything in my apartment:
- **Media**: Jellyfin + the usual *arr suspects for *Linux ISOs*
- **Home Automation**: Home Assistant with ESPHome, Zigbee2MQTT, and Wyoming for voice stuff
- **AI Things**: LibreChat, Whishper, various MCP servers because AI is everywhere now apparently
- **Self-hosted Goodness**: Immich (photos), Actual Budget (money tracking), Traccar (GPS stalking... I mean tracking)
- **Monitoring**: Grafana, Prometheus, Loki, and Beszel because I need pretty graphs
- **Storage**: NAS with Samba because apparently you need that
- **DNS**: AdGuard Home for blocking the internet's nonsense

### prime - Hetzner VPS (x86_64-linux)
The public-facing server that makes everything accessible:
- **Reverse Proxy**: Nginx with automatic SSL
- **Identity**: Kanidm for centralized auth (so I only forget one password)
- **VPN**: Headscale for my Tailscale mesh network
- **Databases**: PostgreSQL instances for apps that need them

### thopter - Lenovo ThinkPad X1 Yoga 7th Gen (x86_64-linux)
My daily driver laptop:
- **Desktop**: Sway because tiling WMs are life
- **Development**: All the tools, all the compilers, all the debuggers
- **Gaming**: Steam + Lutris for Gaming, obviously

### stern - MacBook (aarch64-darwin)
The Mac for when I need to do Mac things:
- **Package Management**: Homebrew for the stuff Nix can't/won't package
- **Development**: Same CLI tools as my Linux machines because consistency
- **Window Management**: Aerospace for tiling on macOS

## The Good Stuff

### Quadlet for Container Management

I wrote a whole [blog post](https://keyruu.de/posts/quadlet/) about this, but TL;DR: Quadlet gives me proper systemd services for each container. That means:
- Individual `systemctl start/stop/restart` commands
- Actual CPU/memory metrics per container (not just the whole compose)
- Automatic restarts that don't nuke everything
- Health checks that actually work
- WUD (What's Up Docker) for keeping track of updates

No more docker-compose bullshit where everything shares one log output and you can't tell what's broken.

### Secrets with SOPS

All secrets are encrypted with [sops-nix](https://github.com/Mic92/sops-nix) using age keys. That means I can commit my secrets to git (encrypted, obviously) and they get decrypted on the hosts. Each host has its own key, containers restart automatically when secrets change, and I don't have to worry about accidentally leaking API keys.

Check out the nginx reverse proxy modules for examples of how this works.

### Networking

- **Tailscale** mesh network connects everything. Doesn't matter if I'm home or at a coffee shop, everything just works.
- **Nginx** reverse proxy with automatic Let's Encrypt SSL via Cloudflare DNS challenges.
- **Headscale** on `prime` for self-hosted Tailscale coordination (because why not).

### Storage

- **ZFS** on `mentat` for data integrity and snapshots
- **Disko** for declarative disk setup - because manual partitioning is for chumps
- **Samba** for network shares so I can access my 10TB of photos from anywhere
- **Backups**: uh... maybe? I should probably work on that.

### Monitoring

- **Grafana** for dashboards that make me feel like a real sysadmin
- **Prometheus** for metrics collection
- **Loki** for log aggregation
- **Beszel** for lightweight system monitoring

## How It's Structured (Blueprint Edition)

I recently restructured everything using [blueprint](https://github.com/numtide/blueprint), which is basically a convention-over-configuration thing for Nix flakes. Instead of manually wiring up all the flake outputs, blueprint just looks at your folder structure and figures it out.

The magic happens in `flake.nix`:
```nix
outputs = inputs: inputs.blueprint {
  inherit inputs;
  prefix = "nix";  # Everything lives in the nix/ folder
};
```

And here's what that folder structure looks like:

```
nix/
├── hosts/              # NixOS and nix-darwin host configurations
│   ├── mentat/        # Host-specific config + modules
│   │   ├── configuration.nix
│   │   ├── hardware-configuration.nix
│   │   └── modules/
│   │       ├── stacks/      # Quadlet container definitions
│   │       ├── adguard.nix
│   │       └── ...
│   ├── prime/
│   ├── thopter/
│   └── stern/         # Darwin host
├── modules/           # Shared/reusable modules
│   ├── nixos/        # NixOS modules
│   ├── darwin/       # nix-darwin modules
│   ├── home/         # Home Manager modules
│   │   ├── linux/
│   │   └── mac/
│   └── services/     # Service-specific modules
├── packages/         # Custom package definitions
└── secrets.yaml      # SOPS encrypted secrets
```

Blueprint automatically:
- Creates `nixosConfigurations` from `nix/hosts/*/configuration.nix`
- Creates `darwinConfigurations` from darwin hosts
- Exposes modules from `nix/modules/`
- Makes packages available from `nix/packages/`

It's pretty neat. No more manually maintaining a giant `flake.nix` with all the outputs.

## The Dependencies

- **nixpkgs** (+ darwin/small variants) - The Nix packages, multiple channels for flexibility
- **blueprint** - Convention-based flake structure (the new hotness)
- **quadlet-nix** - The star of the show, Podman containers as systemd services
- **sops-nix** - Secrets management that doesn't suck
- **home-manager** - User environment configuration
- **nix-darwin** - macOS system configuration
- **disko** - Declarative disk partitioning
- **zen-browser** - Privacy-focused Firefox fork
- **nix-gaming** - Gaming optimizations and fixes
- **vicinae** - Launcher - Raycast alternative for Linux (shoutout to the Vicinae project)
- **sirberus** - My own project integration

## Secrets Management

All secrets are encrypted with sops-nix and stored in `nix/secrets.yaml`. Each host has its own age key derived from its SSH host key, so secrets are automatically decrypted on the right machines.

### Adding a New Host

When you add a new machine, you need to give it access to secrets:

```bash
# Convert the host's SSH key to an age key
nix-shell -p ssh-to-age --run 'ssh-to-age -i /etc/ssh/ssh_host_ed25519_key.pub'
```

Add the output to `.sops.yaml` as a new `server_*` key, then re-encrypt secrets:

```bash
sops updatekeys nix/secrets.yaml
```

### Adding New Secrets

Edit the secrets file with sops:

```bash
sops nix/secrets.yaml
```

Then reference them in your Nix config:

```nix
sops.secrets.mySecret = {
  # Secrets with restartUnits will trigger service restarts on change
  restartUnits = [ "my-service.service" ];
};

# Use in containers via environment templates
sops.templates."my-service.env" = {
  restartUnits = [ "my-service.service" ];
  content = ''
    SECRET=${config.sops.placeholder.mySecret}
  '';
};
```

Check out `CLAUDE.md` or any of the stack modules for more examples.

## Actually Using This Thing

### Prerequisites

- Nix with flakes enabled
- SOPS if you want to edit secrets
- An age key if you want to decrypt stuff

### Deploying

**NixOS hosts:**
```bash
# Deploy to a host
sudo nixos-rebuild switch --flake .#hostname

# Test build without switching
nixos-rebuild build --flake .#hostname
```

**nix-darwin (macOS):**
```bash
sudo darwin-rebuild switch --flake .#stern
```

### Adding a New Service

1. Create a new file in `nix/hosts/<hostname>/modules/stacks/<service>.nix`
2. Follow the Quadlet patterns in `CLAUDE.md`
3. Add any secrets you need to `nix/secrets.yaml`
4. Make sure your service is imported in `nix/hosts/<hostname>/modules/default.nix`
5. Deploy and pray (but it'll probably work because Nix)

## Why "Shinyflakes"?

Because snowflakes are unique, and my setup is definitely... unique. Also "snowflake infrastructure" sounds way cooler than "my random server configs."

## License

Do whatever you want with this. MIT? Apache? Unlicense? Pick your favorite. Just don't blame me if you copy-paste something and it breaks your setup. Individual components (packages, flakes, etc.) have their own licenses - check those too.

## Shoutouts

- [@SEIAROTg](https://github.com/SEIAROTg) for quadlet-nix and actually implementing features I requested
- [@joinemm](https://github.com/joinemm) for having a great config to yoink from (seriously a lot of this has been copied from his conifg)
- The NixOS community for making this whole thing possible
- Anyone who's contributed to the flakes I use

If you're reading this and thinking "this looks cool but complicated" - yeah, it is. But it's also really fun once you get the hang of it. Feel free to steal ideas, patterns, or entire modules. That's what open source is for.
