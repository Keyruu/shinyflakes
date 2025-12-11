{ pkgs, ... }:
{
  services = {
    gvfs.enable = true;
    udisks2.mountOnMedia = true;
    tumbler.enable = true;
  };

  programs = {
    xfconf.enable = true;

    thunar = {
      enable = true;
      plugins = with pkgs.xfce; [
        thunar-archive-plugin
        thunar-volman
        thunar-media-tags-plugin
      ];
    };
  };

  environment.systemPackages = with pkgs; [
    webp-pixbuf-loader # thumbnails for .webp
    ffmpegthumbnailer # thumbnails for video files
    poppler # thumbnails for .pdf
    f3d # thumbnails for 3D model files
  ];
}
