{
  pkgs,
}:
pkgs.python3Packages.buildPythonApplication rec {
  pname = "mcp-proxy";
  version = "0.7.0";

  src = pkgs.fetchFromGitHub {
    owner = "sparfenyuk";
    repo = pname;
    rev = "v${version}";
    sha256 = "sha256-xHy+IwnUoyICSTusqTzGf/kOvT0FvJYcTT9Do0C5DiY=";
  };

  format = "pyproject";

  nativeBuildInputs = [ pkgs.python3Packages.setuptools ];

  propagatedBuildInputs = with pkgs.python3Packages; [
    uvicorn
    mcp
  ];

  meta = with pkgs.lib; {
    description = "A MCP server which proxies requests to a remote MCP server over SSE transport.";
    homepage = "https://github.com/sparfenyuk/mcp-proxy";
    license = licenses.mit;
    mainProgram = "mcp-proxy";
    maintainers = with maintainers; [ keyruu ];
  };
}
