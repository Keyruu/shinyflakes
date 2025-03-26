{...}: {
  programs.vscode = {
    enable = true;
    enableUpdateCheck = false;
    enableExtensionUpdateCheck = true;
    mutableExtensionsDir = true;
  };
}
