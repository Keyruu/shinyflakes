{ ... }:
{
  imports = [
    ./hetzner
    ./cloudflare

    # ./import-generated.nix
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

    backend.s3 = {
      bucket = "terraform-state";
      key = "shinyflakes/terraform.tfstate";
      region = "WEUR";

      endpoints.s3 = "https://e1c020aa1f59e7dd11541054c6e712e3.r2.cloudflarestorage.com";
      skip_credentials_validation = true;
      skip_metadata_api_check = true;
      skip_region_validation = true;
      use_lockfile = true;
      use_path_style = true;
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
