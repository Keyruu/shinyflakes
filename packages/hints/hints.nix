# hints.nix
{ lib, fetchFromGitHub, substituteAll
, python3Packages
, gtk4
, gobject-introspection
, cairo
, pkg-config
, gtk-layer-shell # For Wayland
, grim            # For Wayland
, libwnck3        # For X11
, librsvg         # For SVG icon support
, at-spi2-core    # For accessibility
, wrapGAppsHook4  # For GTK4 apps
, desktop-file-utils # For validating/installing .desktop files
, glib            # For gsettings, general GLib utils
}:

let
  pname = "hints";
  version = "0.3.0"; # Latest tag as of checking AlfredoSequeida/hints

  pythonDeps = with python3Packages; [ # <--- Change this to 'with python3Packages;'
    pygobject3
    dbus-python
    xlib
    setuptools
    pyatspi
  ];
in
python3Packages.buildPythonApplication rec {
  inherit pname version;

  src = fetchFromGitHub {
    owner = "AlfredoSequeida";
    repo = "hints";
    rev = "main";
    # Replace this with the actual hash after the first build attempt
    # You can get it by initially putting: lib.fakeSha256
    # Or run: nix-prefetch-url --unpack https://github.com/AlfredoSequeida/hints/archive/refs/tags/v0.3.0.tar.gz
    hash = "sha256-c46EmdIVyAYmDhRgVc8Roump/DwHynKpj2/7mzxaNiY="; # Placeholder - MUST BE REPLACED
  };

  # The setup.py script for 'hints' uses the HINTS_EXPECTED_BIN_DIR environment
  # variable to correctly set the ExecStart path in the generated hintsd.service file.
  # In a Nix derivation, binaries are placed in $out/bin.
  preBuild = ''
    export HINTS_EXPECTED_BIN_DIR="$out/bin"
  '';

  # We need to patch setup.py to install data files (icons, .desktop, systemd unit)
  # into standard locations within the $out directory, instead of user's $HOME.
  patches = [
    (substituteAll {
      src = ./fix-data-paths.patch; # This patch file is provided below.
      # No dynamic substitutions needed in this specific patch's content.
    })
  ];

  # Python dependencies required by the application.
  propagatedBuildInputs = pythonDeps ++ [
    # Explicitly add at-spi2-core here if it wasn't picked up by buildInputs for runtime
    # This ensures its shared libraries and typelibs are in the runtime closure.
    at-spi2-core # Add here!
  ];
  # propagatedBuildInputs = pythonDeps;

  # System dependencies needed at build time and runtime.
  buildInputs = [
    gtk4
    gobject-introspection # Provides .typelib files for PyGObject
    cairo
    librsvg               # For rendering SVG icons
    at-spi2-core          # Accessibility runtime support
    glib                  # For GSettings schemas (if any) and GLib utilities

    # Wayland specific dependencies (as mentioned in hints README)
    gtk-layer-shell
    grim

    # X11 specific dependency (as mentioned in hints README)
    libwnck3
  ];

  # Tools required during the build process itself.
  nativeBuildInputs = [
    pkg-config
    wrapGAppsHook4        # Sets up environment for GTK4 applications
    desktop-file-utils    # For validating and handling .desktop files
    python3Packages.setuptools # Ensure setuptools is available for the build script
  ];

  # buildPythonApplication handles entry_points automatically.
  # 'hints' setup.py defines 'hints' and 'hintsd' console scripts.
  # These will be installed to $out/bin.

  # The wrapGAppsHook4 will take care of wrapping the executables with
  # necessary environment variables for GTK4 applications.

  meta = with lib; {
    description = "Click, scroll, and drag with your keyboard using hints";
    longDescription = ''
      Hints allows you to navigate GUIs without a mouse by typing hints
      in combination with modifier keys. It provides functionalities like
      single/multiple clicks, right-clicks, dragging, hovering, and scrolling.

      This package installs:
      - The 'hints' application and 'hintsd' daemon to $out/bin.
      - A desktop file to $out/share/applications.
      - An icon to $out/share/icons.
      - A systemd user service file for 'hintsd' to $out/lib/systemd/user/hintsd.service.

      To use the daemon, you might need to enable and start the systemd user service:
      $ systemctl --user enable hintsd.service
      $ systemctl --user start hintsd.service

      Please refer to the application's documentation for enabling system accessibility features,
      which are crucial for 'hints' to function correctly.
    '';
    homepage = "https://github.com/AlfredoSequeida/hints";
    license = licenses.mit; # Verified from the GitHub repository
    maintainers = [ maintainers.yourGithubHandle ]; # TODO: Replace with your GitHub handle
    platforms = platforms.linux;
    notes = ''
      For 'hints' to work correctly, you likely need to enable system-wide accessibility features.
      The 'hints' README suggests setting environment variables like:
      ACCESSIBILITY_ENABLED=1
      GTK_MODULES=gail:atk-bridge
      GNOME_ACCESSIBILITY=1
      QT_ACCESSIBILITY=1

      You might need to add these to your system or session environment (e.g., /etc/environment or shell profile).
    '';
  };
}
