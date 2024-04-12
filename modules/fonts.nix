{pkgs, ...}: {
  fonts = {
    fontconfig = {
      enable = true;

      defaultFonts = {
        emoji = ["Twitter Color Emoji"];
        monospace = ["JetBrainsMono Nerd Font" "Sarasa Gothic"];
        sansSerif = ["Cantarell" "Sarasa Gothic"];
      };

      hinting.style = "full";
      subpixel.rgba = "rgb";
    };

    fontDir = {
      enable = true;
      decompressFonts = true;
    };

    packages = with pkgs; [
      (nerdfonts.override {fonts = ["JetBrainsMono"];})
      cantarell-fonts
      twitter-color-emoji
      sarasa-gothic
    ];
  };
}
