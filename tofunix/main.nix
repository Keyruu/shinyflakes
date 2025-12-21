{ ref, ... }:
{
  imports = [
    ./hetzner
    ./cloudflare
  ];

  terraform = {
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
    cloudflare.default = {
      api_token = ref.var.cloudflare_api_token;
    };
    hcloud.default = {
      token = ref.var.hcloud_token;
    };
  };
}
