  # To edit use your text editor application, for example Nano
  { lib, stdenv, fetchzip, gettext }:

  stdenv.mkDerivation rec {
    pname = "cockpit-podman";
    version = "100";

    src = fetchzip {
      url = "https://github.com/cockpit-project/${pname}/releases/download/${version}/${pname}-${version}.tar.xz";
      sha256 = "sha256-maWRvsVXjpMDYVmm3KS9Z9Du9GNnEGk6rdzDXLeaEik=";
    };

    nativeBuildInputs = [
      gettext
    ];

    makeFlags = [ "DESTDIR=$(out)" "PREFIX=" ];

    postPatch = ''
      substituteInPlace Makefile \
        --replace /usr/share $out/share
      touch pkg/lib/cockpit-po-plugin.js
      touch dist/manifest.json
    '';

    dontBuild = true;

    meta = with lib; {
      description = "Cockpit UI for podman containers";
      license = licenses.lgpl21;
      homepage = "https://github.com/cockpit-project/cockpit-podman";
      platforms = platforms.linux;
      maintainers = [ ];
    };
  }
