# Entry point loaded by tix.toml `[stubs.generate.systems.terranix]` and the
# project's terranix runtime (via blueprint). Re-exports everything in the
# terraform directory so evalModules sees the full config tree.

{ lib, ... }:
{
  imports = [
    ./cloudflare
    ./hetzner
  ];

  terraform = {
    required_providers = {
      cloudflare.source = "registry.opentofu.org/cloudflare/cloudflare";
      hcloud.source = "registry.opentofu.org/hetznercloud/hcloud";
    };

    backend.s3 = {
      bucket = "terraform-state";
      key = "shinyflakes/terraform.tfstate";
      region = "WEUR";

      endpoints.s3 = "https://e1c020aa1f59e7dd11541054c6e712e3.r2.cloudflarestorage.com";
      skip_credentials_validation = true;
      skip_metadata_api_check = true;
      skip_region_validation = true;
      skip_requesting_account_id = true;
      skip_s3_checksum = true;
      # doesnt work with cloudflare R2
      use_lockfile = false;
      use_path_style = true;
    };
  };

  variable = {
    hcloud_token = {
      type = "string";
      sensitive = true;
    };
    cloudflare_api_token = {
      type = "string";
      sensitive = true;
    };
  };

  provider = {
    cloudflare.api_token = lib.tfRef "var.cloudflare_api_token";
    hcloud.token = lib.tfRef "var.hcloud_token";
  };
}
