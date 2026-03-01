_: {
  services.caddy.virtualHostsWithDefaults = {
    "oblivion-test.keyruu.de" = {
      extraConfig = ''
        import cloudflare-only

        handle_path /Homelab/* {
          redir https://keyruu.de/blog{path}/ permanent
        }

        handle_path /MacOS/* {
          redir https://keyruu.de/blog{path}/ permanent
        }

        handle_path /Web-Development/* {
          redir https://keyruu.de/blog{path}/ permanent
        }

        handle {
          redir https://keyruu.de/blog{uri} permanent
        }
      '';
    };
  };
}
