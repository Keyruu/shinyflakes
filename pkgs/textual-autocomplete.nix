{
  python3Packages,
  fetchPypi,
}:
python3Packages.buildPythonPackage rec {
  pname = "textual_autocomplete";
  version = "3.0.0a9";
  pyproject = true;

  src = fetchPypi {
    inherit pname version;
    hash = "sha256-tfPjFIt5Pxcq/mQ6WyGIxewU/LQrY5uYsjExwn5S3oU=";
  };

  build-system = with python3Packages; [
    poetry-core
  ];

  dependencies = with python3Packages; [
    textual
    typing-extensions
  ];
}
