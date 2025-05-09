{...}: let
  version = "0.3.0";
in {
  nixpkgs.overlays = [(
    self: super: {
      wl-kbptr = super.wl-kbptr.overrideAttrs (oldAttrs: {
        inherit version;
        src = super.fetchFromGitHub {
          owner = "moverest";
          repo = "wl-kbptr";
          tag = "v${version}";
          hash = "sha256-T7vxD5FW6Hjqc6io7Hypr6iJRM32KggQVMOGsy2Lg4Q=";  # Replace with the actual hash for v0.3.0
        };
        # Ensure the opencv library is available for the build.
        buildInputs = oldAttrs.buildInputs ++ [ self.opencv ];

        # Extend or override any meson flags; if there were existing flags, keep them.
        mesonFlags = (oldAttrs.mesonFlags or []) ++ [ "-Dopencv=enabled" ];
      });
    }
  )];
}
