{ pkgs }:
pkgs.buildGoModule {
  pname = "niri-workstyle";
  version = "0.1.0";

  src = ./.;

  vendorHash = "sha256-PtwksMRqo9G9F4b73L4+SpX9b1C3vqvA3MfWt9pxpeM=";

  meta = {
    description = "Workspace icons for niri";
    mainProgram = "niri-workstyle";
  };
}
