{ ... }:
{
  imports = [
    ./hetzner
    ./cloudflare

    ./import-generated.nix
  ];

  terraform = {
    required_providers = {
      cloudflare = {
        source = "cloudflare/cloudflare";
        version = "~> 5";
      };
      hcloud = {
        source = "hetznercloud/hcloud";
        version = "~> 1.45";
      };
    };
  };

  variable = {
    hcloud_token = {
      sensitive = true;
    };
    cloudflare_api_token = {
      sensitive = true;
    };
  };

  provider = {
    cloudflare = {
      api_token = "\${var.cloudflare_api_token}";
    };
    hcloud = {
      token = "\${var.hcloud_token}";
    };
  };
}
