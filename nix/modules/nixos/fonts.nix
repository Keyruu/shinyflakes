{ pkgs, ... }:
{
  fonts = {
    fontconfig = {
      enable = true;

      defaultFonts = {
        emoji = [ "Twitter Color Emoji" ];
        monospace = [
          "Maple Mono Normal NL NF"
          "Sarasa Gothic"
        ];
        sansSerif = [
          "Cantarell"
          "Sarasa Gothic"
        ];
      };

      subpixel.rgba = "rgb";
    };

    fontDir = {
      enable = true;
      decompressFonts = true;
    };

    packages = with pkgs; [
      maple-mono.NormalNL-NF
      nerd-fonts.jetbrains-mono
      cantarell-fonts
      twitter-color-emoji
      sarasa-gothic
      corefonts
      dejavu_fonts
    ];
  };
}
