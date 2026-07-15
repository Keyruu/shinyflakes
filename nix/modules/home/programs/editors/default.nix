{ perSystem, ... }: {
  # check nix/packages hx and nvim
  imports = [
    ./vscode
    ./zed
  ];

  programs.neovim = {
    enable = true;
    package = perSystem.self.nvim;
  };
}
