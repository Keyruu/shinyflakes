_: {
  services.caddy.virtualHostsWithDefaults = {
    "oblivion-test.keyruu.de" = {
      extraConfig = ''
        import cloudflare-only

        redir /MacOS/Raycast* https://keyruu.de/blog/raycast/ permanent
        redir /MacOS/Window-Management* https://keyruu.de/blog/window-management/ permanent
        redir /Homelab/Monitoring* https://keyruu.de/blog/monitoring/ permanent
        redir /Homelab/Docker-Compose-on-NixOS* https://keyruu.de/blog/docker-compose-on-nixos/ permanent
        redir /Homelab/NixOS-for-Servers* https://keyruu.de/blog/nixos-for-servers/ permanent
        redir /Homelab/Quadlet* https://keyruu.de/blog/quadlet/ permanent
        redir /Web-Development/Everything-in-Go* https://keyruu.de/blog/everything-in-go/ permanent

        handle {
          redir https://keyruu.de/blog{uri} permanent
        }
      '';
    };
  };
}
