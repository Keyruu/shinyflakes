{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    zmk-nix = {
      url = "github:lilyinstarlight/zmk-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      zmk-nix,
    }:
    let
      lib = nixpkgs.lib;
      forAllSystems = lib.genAttrs (lib.attrNames zmk-nix.packages);

      # Only the ZMK config tree: west.yml pins ZMK plus the Forager shield
      # module and the XIAO status-LED widget.
      src = lib.sourceFilesBySuffices self [
        ".cmake"
        ".conf"
        ".defconfig"
        ".dts"
        ".dtsi"
        ".json"
        ".keymap"
        ".overlay"
        ".shield"
        ".yml"
        "_defconfig"
      ];

      # Hash of the west/Zephyr dependency fetch; bump with west.yml.
      zephyrDepsHash = "sha256-gYtvzbE/8BHhp9EYyMGDHk51xx6xQ7GqaXpaUYnxwH0=";
    in
    {
      packages = forAllSystems (system: {
        default = self.packages.${system}.firmware;

        firmware = zmk-nix.legacyPackages.${system}.buildSplitKeyboard {
          name = "forager-firmware";
          inherit src zephyrDepsHash;
          config = "config";

          # XIAO nRF52840; the Forager shield has no v0.3-era board name.
          board = "xiao_ble//zmk";
          shield = "forager_%PART% rgbled_adapter";
          parts = [
            "left"
            "right"
          ];

          # Studio (keymap editing over USB) lives on the central half.
          enableZmkStudio = true;

          meta = {
            description = "ZMK firmware for the Forager split keyboard";
            license = lib.licenses.mit;
            platforms = lib.platforms.all;
          };
        };

        # Wipes stored BLE bonds/settings: flash this, then reflash the half.
        settings-reset = zmk-nix.legacyPackages.${system}.buildKeyboard {
          name = "forager-settings-reset";
          inherit src zephyrDepsHash;
          config = "config";
          board = "xiao_ble//zmk";
          shield = "settings_reset";

          meta = {
            description = "ZMK settings reset image for the Forager";
            license = lib.licenses.mit;
            platforms = lib.platforms.all;
          };
        };

        flash = zmk-nix.packages.${system}.flash.override {
          firmware = self.packages.${system}.firmware;
        };
      });
    };
}
