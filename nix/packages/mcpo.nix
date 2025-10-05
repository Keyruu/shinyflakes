{
  pkgs,
}:
pkgs.python3Packages.buildPythonApplication rec {
  pname = "mcpo";
  version = "0.0.16";

  src = pkgs.fetchFromGitHub {
    owner = "open-webui";
    repo = "mcpo";
    tag = "v${version}";
    hash = "sha256-T4eAhPgm1ysf/+ZmqZxAoc0SwQbkl8x8lBGwamMYcpU=";
  };

  pyproject = true;

  build-system = [ pkgs.python3Packages.hatchling ];

  dependencies = with pkgs.python3Packages; [
    click
    fastapi
    mcp
    passlib
    pydantic
    pyjwt
    python-dotenv
    typer
    uvicorn
  ];

  nativeCheckInputs = with pkgs.python3Packages; [
    pytestCheckHook
  ];

  meta = {
    description = "A simple, secure MCP-to-OpenAPI proxy server";
    homepage = "https://github.com/open-webui/mcpo";
    mainProgram = "mcpo";
    license = pkgs.lib.licenses.mit;
    maintainers = with pkgs.lib.maintainers; [ keyruu ];
  };
}
