{ den, ... }: {
  den.aspects.editors = {
    includes = with den.aspects.editors; [
      neovim
      vscode
      zed
    ];
  };
}
