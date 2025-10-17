{
  pkgs,
}:
pkgs.python3Packages.buildPythonApplication rec {
  pname = "nextmeeting";
  version = "3.0.0";

  src = pkgs.fetchFromGitHub {
    owner = "chmouel";
    repo = pname;
    rev = "${version}";
    sha256 = "sha256-lw1orSZ6Wbr9u5kr6t7B70AbWNeESnD0M+NjBg9tT5g=";
  };

  pyproject = true;

  build-system = [ pkgs.python3Packages.hatchling ];

  dependencies = with pkgs.python3Packages; [
    python-dateutil
    caldav
  ];

  nativeCheckInputs = with pkgs.python3Packages; [
    pytestCheckHook
  ];

  meta = with pkgs.lib; {
    description = "Show your nextmeeting in your poly/waybar with gcalcli";
    homepage = "https://github.com/chmouel/nextmeeting";
    license = licenses.asl20;
    mainProgram = "nextmeeting";
    maintainers = with maintainers; [ keyruu ];
  };
}
