{ ... }:
{
  den.aspects.mentat.nixos =
    {
      pkgs,
      modulesPath,
      ...
    }:
    {
      imports = [
        (modulesPath + "/installer/scan/not-detected.nix")
      ];

      boot = {
        loader = {
          grub = {
            enable = true;
            efiSupport = true;
            efiInstallAsRemovable = true;
          };
        };
        # use predictable network interface names (eth0)
        kernelParams = [ "net.ifnames=0" ];
      };

      boot.kernelPackages = pkgs.linuxPackages_6_18;

      networking.nftables.enable = true;

      services.resolved.enable = false;

      services.monitoring = {
        metrics = {
          enable = true;
          interface = "eth0";
        };
        logs = {
          enable = true;
          instance = "127.0.0.1";
          lokiAddress = "http://127.0.0.1:3030";
        };
      };

      hardware.cpu.amd.ryzen-smu.enable = true;

      users.groups.smtp.members = [ "root" ];

      sops = {
        secrets = {
          cloudflare.owner = "root";
          resendApiKey = {
            owner = "root";
            group = "smtp";
            mode = "0440";
          };
        };
      };

      environment.systemPackages = with pkgs; [
        vim
        wget
        busybox
        ethtool
        podman-tui
        smartmontools
        pv
        tmux
        slirp4netns
        lazydocker
        usbutils
        conmon
        runc
        powertop
        ryzen-monitor-ng
        isd
        nvtopPackages.nvidia
        rustic
      ];
    };
}
