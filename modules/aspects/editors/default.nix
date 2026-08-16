{ den, ... }: {
  den.aspects.editors.default = {
    includes = with den.aspects.editors; [
      neovim
      vscode
      zed
    ];
  };
}
