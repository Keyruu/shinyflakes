{pkgs, ...}: {
  ##########################################################################
  #
  #  Install all apps and packages here.
  #
  #  NOTE: Your can find all available options in:
  #    https://daiderd.com/nix-darwin/manual/index.html
  #
  # TODO Fell free to modify this file to fit your needs.
  #
  ##########################################################################

  # Install packages from nix's official package repository.
  #
  # The packages installed here are available to all users, and are reproducible across machines, and are rollbackable.
  # But on macOS, it's less stable than homebrew.
  #
  # Related Discussion: https://discourse.nixos.org/t/darwin-again/29331
  environment.systemPackages = with pkgs; [
    neovim
    git
    just # use Justfile to simplify nix-darwin's commands
    jq
  ];
  environment.variables.EDITOR = "nvim";

  # TODO To make this work, homebrew need to be installed manually, see https://brew.sh
  #
  # The apps installed by homebrew are not managed by nix, and not reproducible!
  # But on macOS, homebrew has a much larger selection of apps than nixpkgs, especially for GUI apps!
  homebrew = {
    enable = true;

    onActivation = {
      autoUpdate = false;
      # 'zap': uninstalls all formulae(and related files) not listed here.
      cleanup = "zap";
    };

    # Applications to install from Mac App Store using mas.
    # You need to install all these Apps manually first so that your apple account have records for them.
    # otherwise Apple Store will refuse to install them.
    # For details, see https://github.com/mas-cli/mas
    masApps = {
      # TODO Feel free to add your favorite apps here.

      Xcode = 497799835;
      PastePal = 1503446680;
      Keymapp = 6472865291;
      Tailscale = 1475387142;
      WireGuard = 1451685025;
    };

    taps = [
      "homebrew/services"
      "osx-cross/avr"
      "osx-cross/arm"
      "FelixKratz/formulae"
      "filosottile/musl-cross"
      "graalvm/tap"
      "helm/tap"
      "homebrew/bundle"
      "jkfran/killport"
      "koekeishiya/formulae"
      "lutzifer/tap"
      "messense/macos-cross-toolchains"
      "nikitabobko/tap"
      "osx-cross/arm"
      "osx-cross/avr"
      "quarkusio/tap"
      "keyruu/tap"
    ];

    # `brew install`
    # TODO Feel free to add your favorite apps here.
    brews = [
      "nnn" # terminal file manager

      "helm"
      "ical-buddy" # calendar events

      "coreutils"

      "jenv" # Java environment manager
      "jq"

      "nvm" # Node Version Manager
      "fisher"

      "pnpm" # package manager

      "python@3.10"
      "python@3.11"
      "python@3.12"

      "php@8.1"
      "php@8.2"
      "php@8.3"
      "composer"

      "borders"
      # "sketchybar" # status bar
      # "skhd" # hotkey daemon
      # "svim" # make every text field a vim editor

      "x86_64-unknown-linux-gnu" # cross-compilation
      "x86_64-unknown-linux-musl" # cross-compilation
      # "yabai" # window manager

      # libraries, codecs and stuff i have no idea what they are
      # "aom" # AV1 video codec
      # "aria2" # download tool
      # "aribb24" # ARIB STD-B24 caption support
      "bdw-gc" # garbage collector
      # "berkeley-db@5" # database
      # "blueutil" # bluetooth control
      # "boost" # C++ library
      # "bootloadhid" # HID bootloader
      # "brotli" # compression
      # "c-ares" # DNS library
      # "cabextract" # extract Microsoft cabinet files
      # "cairo" # graphics library
      # "capstone" # disassembly framework
      # "cdrtools" # CD/DVD/Blu-ray burning
      # "certifi" # CA certificates
      # "cffi" # C Foreign Function Interface
      # "cjson" # JSON parser
      # "clang-format" # code formatter
      # "confuse" # configuration file parser
      # "cryptography" # encryption library
      # "dav1d" # AV1 decoder
      # "dtc" # device tree compiler
      # "flac" # audio codec
      # "fontconfig" # font configuration
      # "freetype" # font library
      # "frei0r" # video effects
      # "fribidi" # bidirectional text
      "gcc" # C compiler
      # "gdbm" # database
      # "giflib" # GIF library
      # "glib" # general-purpose utility library
      "gmp" # math library
      # "gnu-sed" # text editor
      # "gnupg" # encryption
      # "gnutls" # TLS library
      # "gpgme" # GnuPG Made Easy
      # "graphite2" # font rendering
      "guile" # Scheme programming language
      # "harfbuzz" # text shaping
      # "hidapi" # USB HID library
      # "highway" # SIMD library
      # "icu4c" # Unicode library
      # "imath" # integer library
      # "isl" # integer set library
      # "jansson" # JSON library
      # "jpeg-turbo" # JPEG library
      # "jpeg-xl" # JPEG-XL image format
      # "jsoncpp" # JSON library
      # "lame" # MP3 encoder
      # "leptonica" # image processing
      # "libarchive" # archive library
      # "libass" # subtitle renderer
      # "libassuan" # IPC library
      # "libb2" # BLAKE2 library
      # "libbluray" # Blu-ray library
      # "libevent" # event notification library
      # "libftdi" # FTDI library
      # "libgcrypt" # cryptography library
      # "libgit2" # Git library
      # "libgpg-error" # GnuPG error library
      "libiconv" # character set conversion library
      # "libidn2" # internationalized domain names
      # "libimagequant" # image quantization
      # "libksba" # X.509 library
      # "libmagic" # file type identification
      # "libmicrohttpd" # HTTP server
      # "libmpc" # math library
      # "libnet" # network library
      # "libnghttp2" # HTTP/2 library
      # "libogg" # audio codec
      # "libpng" # image format library
      # "libpq" # PostgreSQL library
      # "libpthread-stubs" # POSIX threads
      # "libraqm" # text layout
      # "librist" # Reliable Internet Stream Transport
      # "libsamplerate" # audio sample rate converter
      # "libslirp" # SLiRP library
      # "libsndfile" # audio library
      # "libsodium" # encryption library
      # "libsoxr" # audio resampler
      # "libssh"
      # "libssh2"
      # "libtasn1"
      # "libtermkey"
      # "libtiff"
      "libtool"
      # "libunibreak"
      "libunistring"
      # "libusb"
      # "libusb-compat"
      # "libuv"
      # "libvidstab"
      # "libvmaf"
      # "libvorbis"
      # "libvpx"
      # "libvterm"
      # "libx11"
      # "libxau"
      # "libxcb"
      # "libxdmcp"
      # "libxext"
      # "libxrender"
      # "little-cms2" # color management
      # "luajit" # Lua programming language
      # "luv" # libuv bindings for Lua
      "lz4" # compression
      # "lzo" # compression
      "m4" # macro processor
      # "mbedtls" # TLS library
      # "mpdecimal" # decimal arithmetic
      # "mpfr" # math library
      # "mpg123" # audio player
      # "msgpack" # serialization library
      # "ncurses" # terminal library
      # "nettle" # cryptographic library
      # "npth" # GnuPG library
      # "oniguruma" # regular expressions
      # "openblas" # BLAS library
      # "opencore-amr" # audio codec
      # "openexr" # image library
      # "openjpeg" # JPEG 2000 library
      # "openldap" # LDAP library
      "openssl@1.1" # encryption library
      "openssl@3" # encryption library
      # "openvino" # Intel OpenVINO
      # "opus" # audio codec
      # "p11-kit" # PKCS#11 library
      # "pango" # text layout
      # "pcre2" # regular expressions
      # "pinentry" # GnuPG password entry
      # "pixman" # pixel manipulation
      "pkg-config" # package configuration
      "portaudio" # audio library
      # "pugixml" # XML parser
      # "pycparser" # C parser
      # "pillow" # image processing
      "pcre2" # something for php/apcu
      # "rav1e" # AV1 encoder
      # "rubberband" # audio time-stretching
      # "screenresolution" # screen resolution
      # "sdl2" # Simple DirectMedia Layer
      # "six" # Python 2 and 3 compatibility
      # "snappy" # compression
      # "speex" # audio codec
      # "srt" # Secure Reliable Transport
      # "svt-av1" # AV1 encoder
      # "tbb" # threading library
      # "tcl-tk" # scripting language
      # "tcptraceroute" # traceroute
      # "teensy_loader_cli" # Teensy loader
      # "theora" # video codec
      # "tokyo-cabinet" # database
      # "webp" # image format
      # "wimlib" # Windows Imaging Format
      # "x264" # video codec
      # "x265" # video codec
      # "xorgproto" # X.Org protocol headers
      # "xvid" # video codec
      # "xz" # compression
      # "zeromq" # messaging library
      # "zimg" # image scaling
      "zstd" # compression
    ];

    # `brew install --cask`
    # TODO Feel free to add your favorite apps here.
    casks = [
      "arc"

      # IM & audio & remote desktop & meeting
      "telegram"
      "discord"

      # "anki" # flashcard
      # "iina" # video player
      # "stats" # beautiful system monitor
      "shottr"
      "jordanbaird-ice"
      "nikitabobko/tap/aerospace"
      "keyruu/tap/keyruu-tabula"
      "protonmail-bridge"
      # "superproductivity"
      # "betterdisplay"

      # Development
      # "insomnia" # REST client
      "wireshark" # network analyzer

      "1password-cli"
      "bruno"
      # "macgesture"
      "notion"
      "postman"
      "rar"
      "sf-symbols"
      "shortcat"
      "temurin@11"
      "temurin@17"
      "temurin@21"
      "obs"
      "kdenlive"
      "bambu-studio"

      "raycast"

      "balenaetcher"
      "raspberry-pi-imager"
      "qutebrowser"
      "zen-browser"
    ];
  };
}
