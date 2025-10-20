{
  pkgs,
}:
pkgs.buildFishPlugin {
  pname = "aws";
  version = "0-unstable-2023-08-03";

  src = pkgs.fetchFromGitHub {
    owner = "Realiserad";
    repo = "fish-ai";
    rev = "v2.3.1";
    hash = "sha256-l17v/aJ4PkjYM8kJDA0zUod7UTsfFqq+Prei/Qq0DRA=";
  };
}
