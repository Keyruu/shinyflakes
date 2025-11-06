{ ... }:
let
  juniqeRepos = [
    "content-insights"
    "creator-admin-backend"
    "frontends"
    "gotenberg"
    "jq-shop-production"
    "jq-shop-staging"
    "monetary"
    "sales"
    "tf-cloudflare"
  ];

  kartenliebeRepos = [
    "k8s-cluster"
    "kl-shop-production"
    "kl-shop-staging"
    "tf-domains"
  ];

  myposterRepos = [
    "all-in-flare"
    "allin-cli"
    "aws-build-push-image-action"
    "aws-management"
    "base-php"
    "dashboard-service"
    "designer-library"
    "dev-cluster"
    "get-latest-tag-value-action"
    "get-next-helm-version-action"
    "github-actions-testing"
    "install-tools-action"
    "k6-loadtest"
    "k8s-cluster"
    "mp-shop-production"
    "mp-shop-staging"
    "prompts"
    "publish-helm-chart-to-museum-action"
    "publish-terraform-module-to-s3-action"
    "qai-hub"
    "rds-dump"
    "serverless-image-handler"
    "shared-deployment-workflows"
    "shop-backend"
    "shop-frontends"
    "sre-agent"
    "staging-management"
    "terraform-ci"
    "tf-aws-ecr"
    "tf-cloudflare"
    "tf-modules"
  ];

  privateRepos = [
    "advent-of-code-2024"
    "buymeaspezi"
    "dialogger"
    "homepage"
    "iac"
    "nexcalimat"
    "niri-flake"
    "nirius"
    "oblivion"
    "sirberus"
    "tabula"
    "traversetown"
    "traversetown-htmx"
  ];

  # Function to generate mr settings for a list of repos
  mkRepoSettings =
    orgName: githubOrg: repos:
    builtins.listToAttrs (
      map (repo: {
        name = "git/${orgName}/${repo}";
        value = {
          checkout = "git clone git@github.com:${githubOrg}/${repo}.git";
        };
      }) repos
    );

  # Generate all repository settings
  allRepoSettings =
    (mkRepoSettings "juniqe" "juniqe-com" juniqeRepos)
    // (mkRepoSettings "kartenliebe" "kartenliebe" kartenliebeRepos)
    // (mkRepoSettings "myposter" "myposter-de" myposterRepos)
    // (mkRepoSettings "private" "keyruu" privateRepos);

in
{
  programs.mr = {
    enable = true;
    settings = allRepoSettings;
  };
}
