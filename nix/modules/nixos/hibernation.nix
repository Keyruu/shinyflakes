{
  boot = {
    kernelParams = [
      "resume_offset=533760"
      "mem_sleep_default=deep"
    ];
    resumeDevice = "/dev/disk/by-label/nixos";
  };

  services.logind.settings.Login = {
    HandleLidSwitch = "lock";
    HandlePowerKey = "suspend";
    HandlePowerKeyLongPress = "poweroff";
  };

  # Define time delay for hibernation
  systemd.sleep.extraConfig = ''
    HibernateDelaySec=30m
    SuspendState=mem
  '';
}
