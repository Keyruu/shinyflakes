_: {
  programs.opencode = {
    enable = true;
    settings = {
      permission = {
        edit = "ask";
        bash = "ask";
        webfetch = "allow";
        doom_loop = "ask";
        external_directory = "ask";
      };
      provider = {
        mammouth = {
          npm = "@ai-sdk/openai-compatible";
          name = "Mammouth";
          options = {
            baseURL = "https://api.mammouth.ai/v1";
            apiKey = "{env:MAMMOUTH_API_KEY}";
            # headers = {
            #   "Authorization" = "Bearer custom-token";
            # };
          };
          models = {
            claude-sonnet-4-5 = {
              "name" = "claude-sonnet-4-5";
            };
            claude-opus-4-5 = {
              "name" = "claude-opus-4-5";
            };
            codestral-2508 = {
              "name" = "codestral-2508";
            };
          };
        };
      };
    };
  };
}
