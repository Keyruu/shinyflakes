{
  hostname,
  lib,
  pkgs,
  ...
}:
{
  services.telegraf = {
    enable = true;
    extraConfig = {
      inputs = {
        cpu = {
          percpu = true;
          totalcpu = true;
          collect_cpu_time = false;
          report_active = false;
        };
        disk = {
          mount_points = [ "/" ];
        };
        diskio = {
          devices = [ "*" ];
        };
        net = {
          ignore_protocol_stats = true;
        };
        mem = { };
        processes = { };
        swap = { };
        system = { };
        netstat = { };
        smart = {
          path_smartctl = "${lib.getExe pkgs.smartmontools}";
        };
        procstat = {
          pid_finder = "native";
          filter = [
            {
              name = "all_cgroup";
              cgroups = [ "/sys/fs/cgroup/system.slice/*.service" ];
            }
          ];
        };
        docker = {
          endpoint = "unix:///run/podman/podman.sock";
        };
        zfs = { };
      };
      outputs = {
        prometheus_client = {
          listen = ":9273";
        };
      };
    };
  };

  systemd.services.telegraf.serviceConfig.SupplementaryGroups = [ "podman" ];
}
