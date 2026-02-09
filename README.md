<img src="docs/shinyflakes.png" width="200" />

# ✨ shinyflakes ❄️

My personal NixOS/nix-darwin homelab setup. Everything from servers to desktops
to laptops, all defined in one git repo. Because if it's not in git, did it even
happen?

## Why Though?

I use NixOS to manage my homelab and it's been pretty awesome having my whole
infrastructure version-controlled. No more "it worked on my machine" moments -
my machines ARE the configuration.

The secret sauce here is using
[Quadlet](https://docs.podman.io/en/latest/markdown/podman-systemd.unit.5.html)
(via [quadlet-nix](https://github.com/SEIAROTg/quadlet-nix)) for container
management.

### Why not NixOS services?

Because versioning is just horrendous. I can't really control versions of
specific services if I don't want to have 100 flake inputs. Also with container
images I always get the newest version as soon as its out.

### Why not docker-compose?

Because I want proper systemd integration, individual container metrics, and the
ability to manage each container separately - not just restart the whole
docker-compose when one thing breaks. Plus, Nix lets me do cool stuff like
ensuring directories exist before mounting them, templating configs with
secrets, and using actual Nix references between resources.

## The Fleet

### mentat - Main homelab server (x86_64-linux)

The big boi running everything in my apartment:

- **Media**: Jellyfin, Navidrome, and the full *arr stack for _Linux ISOs_ and
  music
- **Home Automation**: Home Assistant with ESPHome, Zigbee2MQTT and Music
  Assistant
- **AI Things**: ~~Ollama + Open WebUI,~~ LibreChat ~~, Perplexica,~~ various
  MCP servers because AI is everywhere now apparently (I took my GPU out of the
  server because of the power draw...)
- **Self-hosted Goodness**: Immich (photos), Forgejo (git), Dawarich (location
  tracking), Copyparty (file sharing)
- **Monitoring**: Grafana, Prometheus, Loki, Beszel, Renovate for keeping tabs
  on container and flake.lock updates
- **Storage**: Garage (S3-compatible storage), NAS with Samba, ZFS for data
  integrity
- **DNS**: AdGuard Home for blocking the internet's nonsense
- **GitOps**: Comin for automatic deployments because manual deploys are so 2023

### prime - Hetzner VPS (x86_64-linux)

The public-facing server that makes everything accessible:

- **Reverse Proxy**: Caddy with Coraza for a self-hosted WAF solution, because I
  am paranoid (rightfully so)
- **Identity**: Kanidm for centralized auth (so I only forget one password)
- **VPN**: My self made mesh network with WireGuard (everything is declarative)
- **GitOps**: Comin for automatic deployments because manual deploys are so 2023

### carryall, thopter - Lenovo ThinkPad T14s (x86_64-linux)

My work and private laptop:

- **Desktop**: NNN is the goat, that stands for NixOS, Noctalia-Shell and Niri.
  This definitely is my favorite way to use a DE now.
- **Development**: All the tools, all the compilers, all the debuggers
- **Security**: Lanzaboote for secure boot with TPM because we're fancy now
- **Boot**: Plymouth for those sick boot animations
- **Extras**: Fingerprint auth, auto-rotation, distrobox for when Nix isn't
  enough

### muadib - Tower Desktop for gaming (x86_64-linux)

Shares most of the config with the laptops, but of course has:

- **Gaming**: Steam + Lutris for procrastination

## The Good Stuff

### Quadlet for Container Management

I wrote a whole [blog post](https://keyruu.de/posts/quadlet/) about this, but
TL;DR: Quadlet gives me proper systemd services for each container. That means:

- Individual `systemctl start/stop/restart` commands
- Actual CPU/memory metrics per container (not just the whole compose)
- Automatic restarts that don't nuke everything
- Health checks that actually work
- Renovate for keeping track of updates
- Generic alerts for systemd will also alert me of failing containers

No more docker-compose bullshit where everything shares one log output and you
can't tell what's broken.

### Secrets with SOPS

All secrets are encrypted with [sops-nix](https://github.com/Mic92/sops-nix)
using age keys. That means I can commit my secrets to git (encrypted, obviously)
and they get decrypted on the hosts. Each host has its own key, containers
restart automatically when secrets change, and I don't have to worry about
accidentally leaking API keys.

Check out the nginx reverse proxy modules for examples of how this works.

### Networking

- **WireGuard** mesh network connects everything. Doesn't matter if I'm home or
  at a coffee shop, everything just works. This is very custom and is using my
  own module. I will probably write a blogpost about that setup one day.
- **Nginx** reverse proxy with automatic Let's Encrypt SSL via Cloudflare DNS
  challenges. And a whitelist to not allow everybody on the mesh to access every
  service.

### Storage

- **ZFS** on `mentat` for data integrity and snapshots
- **Disko** for declarative disk setup - because manual partitioning is for
  chumps
- **Samba** for network shares I guess
- **Backups**: ~~uh... maybe? I should probably work on that.~~ I have that now.
  Everything gets backupped every night via restic!

### Monitoring

- **Grafana** for dashboards that make me feel like a real sysadmin
- **Prometheus** for metrics collection
- **Loki** for log aggregation
- **Beszel** for lightweight system monitoring
- **Renovate** for tracking container updates

### Infrastructure as Code

- **Tofunix** for managing Terraform with Nix because why have two config
  languages when you can have one?
  - Cloudflare DNS records
  - Hetzner Cloud resources
  - S3 backend in Cloudflare R2 for state management

## How It's Structured (Blueprint Edition)

I recently restructured everything using
[blueprint](https://github.com/numtide/blueprint), which is basically a
convention-over-configuration thing for Nix flakes. Instead of manually wiring
up all the flake outputs, blueprint just looks at your folder structure and
figures it out.

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
- Exposes modules from `nix/modules/`
- Makes packages available from `nix/packages/`

It's pretty neat. No more manually maintaining a giant `flake.nix` with all the
outputs.

## The Dependencies

- **nixpkgs** (+ stable/small variants) - The Nix packages, multiple channels
  for flexibility
- **blueprint** - Convention-based flake structure (the new hotness)
- **quadlet-nix** - The star of the show, Podman containers as systemd services
- **sops-nix** - Secrets management that doesn't suck
- **home-manager** - User environment configuration
- **disko** - Declarative disk partitioning
- **lanzaboote** - Secure boot for NixOS with TPM support
- **zen-browser** - Privacy-focused Firefox fork
- **nix-gaming** - Gaming optimizations and fixes
- **vicinae** - Launcher - Raycast alternative for Linux (shoutout to the
  Vicinae project)
- **niri** - Scrollable tiling Wayland compositor
- **spicetify-nix** - Spotify theming because aesthetics matter
- **nvf** - Neovim configuration framework
- **iio-sway** - Auto-rotation for convertible laptops
- **nix-flatpak** - Declarative Flatpak management
- **comin** - GitOps for NixOS (automatic deployments)
- **niks3** - S3 backend support for Nix binary caches
- **copyparty** - Simple file sharing server
- **sirberus** - My own project integration

## Secrets Management

All secrets are encrypted with sops-nix and stored in `nix/secrets.yaml`. Each
host has its own age key derived from its SSH host key, so secrets are
automatically decrypted on the right machines.

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

## Installing a New Host

### Prerequisites

- NixOS minimal ISO USB drive
- Internet connection (Ethernet or WiFi)
- Your disk partition scheme ready (check the disko configs in
  `nix/hosts/*/disko.nix`)

### Installation Steps

#### 1. Boot the Installer

Boot from the NixOS minimal ISO and wait for the prompt.

#### 2. Connect to Internet

**Ethernet:** Should work automatically.

**WiFi:**

```bash
# Start wpa_supplicant
sudo systemctl start wpa_supplicant

# Connect to WiFi
wpa_cli
> add_network
> set_network 0 ssid "YourWiFiName"
> set_network 0 psk "YourPassword"
> enable_network 0
> quit

# Verify connection
ping nixos.org
```

#### 3. Copy the flake

```bash
git clone https://github.com/Keyruu/shinyflakes.git
cd shinyflakes
```

#### 4. Identify Your Disk

Before partitioning, make sure you know which disk you're targeting:

```bash
# List all block devices with size and model info
lsblk -f

# List disks by ID (useful for disko configs)
ls -l /dev/disk/by-id/
```

Update your disko configuration to use the correct disk path. Using
`/dev/disk/by-id/` is recommended for consistency.

#### 5. Partition with Disko

**Warning:** This will erase your disk. Double-check you're targeting the right
device!

```bash
# Run disko with your host's configuration
sudo nix --experimental-features "nix-command flakes" run github:nix-community/disko -- \
  --mode destroy,format,mount ./nix/hosts/hostname/disko.nix

# Verify everything is mounted
mount | grep /mnt
df -h
```

#### 6. Generate Hardware Configuration

```bash
# Generate hardware config WITHOUT filesystem definitions (disko handles that)
sudo nixos-generate-config --no-filesystems --root /mnt

# This creates /mnt/etc/nixos/hardware-configuration.nix
# Copy it to your host config directory
sudo cp /mnt/etc/nixos/hardware-configuration.nix ./nix/hosts/hostname/
```

#### 7. Copy Configuration to System

```bash
# Copy the entire flake to the system partition
sudo cp -r ./ /mnt/etc/nixos/

# Verify it's there
ls -la /mnt/etc/nixos/
```

#### 8. Install NixOS

```bash
sudo nixos-install --flake /mnt/etc/nixos#hostname
```

#### 9. Set User Password

```bash
# If needed, set your user password
sudo nixos-enter --root /mnt
passwd lucas
exit
```

#### 10. Reboot

```bash
# Unmount and reboot
sudo umount -R /mnt
sudo reboot
```

Remove the USB drive when prompted. Your system should now boot into your
configured NixOS installation, with the flake configuration already present in
`/etc/nixos/`.

## Secure Boot with Lanzaboote

If you want secure boot (and who doesn't?), you can set it up after
installation. Lanzaboote gives you secure boot on NixOS with automatic signing
of your kernel and initrd.

### Prerequisites

Make sure your host config includes Lanzaboote:

```nix
{
  imports = [
    inputs.lanzaboote.nixosModules.lanzaboote
    flake.modules.nixos.secure-boot
  ];

  # Use systemd-boot instead of grub
  boot.loader.systemd-boot.enable = lib.mkForce false;
}
```

### Setup Steps

1. **Boot into your new NixOS system** and make sure Lanzaboote is configured.

2. **Create secure boot keys:**

```bash
sudo sbctl create-keys
```

3. **Put your system into Setup Mode:**
   - Reboot and enter your BIOS/UEFI settings (usually F2, F10, F12, or Del
     during boot)
   - Find the Secure Boot settings
   - Clear all existing keys or enable "Setup Mode"
   - Save and exit back to your system

4. **Enroll your keys:**

```bash
# Check that you're in setup mode
sudo sbctl status

# Enroll keys (includes Microsoft's keys for compatibility)
sudo sbctl enroll-keys --microsoft
```

5. **Enable secure boot:**
   - Reboot and enter BIOS/UEFI settings again
   - Enable Secure Boot
   - Save and reboot

Your system should now boot with secure boot enabled. You can verify with:

```bash
sudo sbctl status
```

### TPM2 Disk Encryption

If you're using LUKS encryption and have a TPM2 chip, you can unlock your disk
automatically on boot:

```bash
# Enroll your LUKS partition with TPM2
# Replace /dev/nvme0n1p2 with your actual LUKS partition
sudo systemd-cryptenroll --tpm2-device=auto --tpm2-pcrs=0+2+7+12 --wipe-slot=tpm2 /dev/nvme0n1p2
```

**What those PCRs mean:**

- PCR 0: UEFI firmware and settings
- PCR 2: Boot loader code
- PCR 7: Secure boot state
- PCR 12: Kernel command line and initrd

Now your disk unlocks automatically on boot, but only if secure boot is enabled
and nothing in the boot chain has been tampered with.

**Warning:** If you change BIOS settings or disable secure boot, you'll need to
manually enter your password. Keep that recovery key handy.

## Deploying Updates

Once you have a host installed, deploying changes is straightforward:

**NixOS hosts:**

```bash
# Deploy to a host
sudo nixos-rebuild switch --flake .#hostname

# Test build without switching
nixos-rebuild build --flake .#hostname

# Test without making it permanent (reverts on reboot)
sudo nixos-rebuild test --flake .#hostname
```

**Prerequisites for managing the config:**

- Nix with flakes enabled
- SOPS if you want to edit secrets (see Secrets Management section)
- An age key if you want to decrypt secrets

## Why "Shinyflakes"?

There was a big teenage drug dealer here in Germany that sold drugs on the
internet from a small town. He got caught but did do a documentary called
_shinyflakes_. This also has inspired a german Netflix show called "How to sell
drugs online (fast)", which is very good and definitely worth a watch.

So why is my repo named like that? Idk flakes are a big concept in Nix and I
thought that sounded cool for a repo name.

## License

Do whatever you want with this. MIT? Apache? Unlicense? Pick your favorite. Just
don't blame me if you copy-paste something and it breaks your setup. Individual
components (packages, flakes, etc.) have their own licenses - check those too.

## Shoutouts

- [@SEIAROTg](https://github.com/SEIAROTg) for quadlet-nix and actually
  implementing features I requested
- [@joinemm](https://github.com/joinemm) for having a great config to yoink from
  (seriously a lot of this has been copied from his conifg) and showing me
  NixOS!
- [@Mic92](https://github.com/Mic92) for building what feels like half of the
  Nix ecosystem
- The monthly NixOS meetup in Munich that led me to meet a bunch of awesome
  people and taught me a lot about NixOS
- The NixOS community for making this whole thing possible
- Anyone who's contributed to the flakes I use

If you're reading this and thinking "this looks cool but complicated" - yeah, it
is. But it's also really fun once you get the hang of it. Feel free to steal
ideas, patterns, or entire modules. That's what open source is for.
