{
  username,
  ...
}:
{
  imports = [
    ../common/common.nix
    ../common/neovim
    ../common/intellij.nix
    ../common/kubie.nix
    ../common/shell
    ../common/programs/kitty.nix
    ../common/programs/zathura.nix
    ../common/programs/helix.nix
    ../common/programs/nh.nix
    ../common/programs/opencode.nix
    ../common/bin.nix
    ../common/ssh.nix
    ./scripts
    ./aerospace.nix
    ./kanata.nix
    ./borders.nix
  ];

  # Home Manager needs a bit of information about you and the
  # paths it should manage.
  home = {
    username = username;
    homeDirectory = "/Users/${username}";

    # This value determines the Home Manager release that your
    # configuration is compatible with. This helps avoid breakage
    # when a new Home Manager release introduces backwards
    # incompatible changes.
    #
    # You can update Home Manager without changing this value. See
    # the Home Manager release notes for a list of state version
    # changes in each release.
    stateVersion = "24.11";
  };

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;
}
