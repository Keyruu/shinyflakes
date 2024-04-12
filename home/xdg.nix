{
  user,
  pkgs,
  ...
}: {
  xdg = {
    enable = true;
    userDirs = {
      enable = true;
      desktop = "/home/${user}";
      templates = "/home/${user}";
      publicShare = "/home/${user}";
      documents = "/home/${user}/documents";
      download = "/home/${user}/downloads";
      music = "/home/${user}/music";
      pictures = "/home/${user}/pictures";
      videos = "/home/${user}/videos";
    };

    mimeApps = {
      enable = true;
      defaultApplications = let
        file-manager = "pcmanfm.desktop";
        editor = "nvim.desktop";
        browser = "firefox.desktop";
        video-player = "mpv.desktop";
        image-viewer = "imv-dir.desktop";
      in {
        "application/pdf" = ["org.pwmt.zathura-pdf-mupdf.desktop"];
        "image/gif" = ["nsxiv.desktop"];
        "image/jpeg" = [image-viewer];
        "image/png" = [image-viewer];
        "image/webp" = [image-viewer];
        "inode/directory" = [file-manager];
        "text/csv" = [editor];
        "text/html" = [browser];
        "text/plain" = [editor];
        "video/mp4" = [video-player];
        "video/webm" = [video-player];
        "video/x-matroska" = [video-player];
        "x-scheme-handler/http" = [browser];
        "x-scheme-handler/https" = [browser];
        "x-scheme-handler/chrome" = [browser];
        "application/x-extension-htm" = [browser];
        "application/x-extension-html" = [browser];
        "application/x-extension-shtml" = [browser];
        "application/xhtml+xml" = [browser];
        "application/x-extension-xhtml" = [browser];
        "application/x-extension-xht" = [browser];
        "x-scheme-handler/magnet" = ["transmission-magnet.desktop"];
        "x-scheme-handler/prusaslicer" = ["PrusaSlicerURLProtocol.desktop"];
        "x-scheme-handler/nxm" = ["modorganizer2-nxm-handler.desktop"];
      };
    };
  };
}
