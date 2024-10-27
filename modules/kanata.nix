{pkgs, inputs, ...}: {
  launchd.user.agents."kanata" = {
    serviceConfig = {
      KeepAlive = true;
      RunAtLoad = true;
      Label = "org.nixos.kanata";
      StandardErrorPath = "/tmp/kanata.err.log";
      StandardOutPath = "/tmp/kanata.out.log";
    };
    script = ''
      sudo ${inputs.kanata.packages.${pkgs.stdenv.hostPlatform.system}.default}/bin/kanata -c ${./kanata.kbd}
    '';
  };
}
