{ ... }:
{
  home.file.".config/opencode/config.json".text = # json
    ''
      {
        "$schema": "https://opencode.ai/config.json",
        "mcp": {
          "github": {
            "type": "remote",
            "url": "http://highwind:30000/sse"
          },
          "fetch": {
            "type": "remote",
            "url": "http://highwind:30001/sse"
          },
          "atlassian": {
            "type": "remote",
            "url": "http://highwind:30002/sse"
          },
          "searxng": {
            "type": "remote",
            "url": "http://highwind:30003/sse"
          }
        }
      }
    '';
}
