{
  pkgs,
  ...
}:
pkgs.vimUtils.buildVimPlugin {
  name = "jira-nvim";
  src = pkgs.fetchFromGitHub {
    owner = "letieu";
    repo = "jira.nvim";
    rev = "499a96ac73afdb858dd031a81a98dc0c3efb0516";
    hash = "sha256-qckHcBrYf0PE7SwrBvk+UKwgzuXxb0nrk71c/dW8m7I=";
  };
}
