{
  config,
  pkgs,
  lib,
  ...
}:
{
  hardware = {
    nvidia = {
      # Modesetting is required.
      modesetting.enable = true;

      # Nvidia power management. Experimental, and can cause sleep/suspend to fail.
      # Enable this if you have graphical corruption issues or application crashes after waking
      # up from sleep. This fixes it by saving the entire VRAM memory to /tmp/ instead
      # of just the bare essentials.
      powerManagement.enable = false;

      # Fine-grained power management. Turns off GPU when not in use.
      # Experimental and only works on modern Nvidia GPUs (Turing or newer).
      powerManagement.finegrained = false;

      # Use the NVidia open source kernel module (not to be confused with the
      # independent third-party "nouveau" open source driver).
      # Support is limited to the Turing and later architectures. Full list of
      # supported GPUs is at:
      # https://github.com/NVIDIA/open-gpu-kernel-modules#compatible-gpus
      # Only available from driver 515.43.04+
      open = true;

      # Enable the Nvidia settings menu,
      # accessible via `nvidia-settings`.
      nvidiaSettings = true;

      package = config.boot.kernelPackages.nvidiaPackages.stable;

      datacenter.enable = false;
    };

    nvidia-container-toolkit.enable = true;
  };

  services.xserver.videoDrivers = [ "nvidia" ];

  nixpkgs.config.allowUnfreePredicate =
    pkg:
    builtins.elem (lib.getName pkg) [
      "nvidia-x11"
      "nvidia-settings"
      # "cuda-merged"
      # "cuda_cuobjdump"
      # "cuda_gdb"
      # "cuda_nvcc"
      # "cuda_nvdisasm"
      # "cuda_nvprune"
      # "cuda_cccl"
    ]
    || lib.all (
      license:
      license.free
      || lib.elem license.shortName [
        "CUDA EULA"
        "cuDNN EULA"
        "cuSPARSELt EULA"
        "cuTENSOR EULA"
        "NVidia OptiX EULA"
      ]
    ) (lib.toList pkg.meta.license);

  # System packages
  environment.systemPackages = with pkgs; [
    # CUDA development tools
    cudatoolkit
    cudaPackages.cudnn
    cudaPackages.libcutensor

    # GPU monitoring and utilities
    nvidia-container-toolkit
  ];

  # Environment variables
  environment.variables = {
    CUDA_PATH = "${pkgs.cudatoolkit}";
    CUDA_ROOT = "${pkgs.cudatoolkit}";
    # Important for Podman GPU support
    # NVIDIA_VISIBLE_DEVICES = "all";
    # NVIDIA_DRIVER_CAPABILITIES = "compute,utility,graphics";
  };

  systemd.tmpfiles.rules = [
    "d /etc/cdi 0755 root root"
  ];

  systemd.services.nvidia-container-toolkit-cdi-generator-custom = {
    description = "Generate CDI spec for NVIDIA GPUs";
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = "${pkgs.nvidia-container-toolkit}/bin/nvidia-ctk cdi generate --output=/etc/cdi/nvidia.yaml --nvidia-ctk-path /nix/store/rqpzqiqjyklr2h6iw0iysh9s0vb7k536-nvidia-container-toolkit-1.17.8/bin/nvidia-ctk";
    };
  };
}
