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
            gpt-5-2-chat = {
              "name" = "gpt-5.2-chat";
            };
            gpt-5-1-chat = {
              "name" = "gpt-5.1-chat";
            };
            gpt-5-mini = {
              "name" = "gpt-5-mini";
            };
            gpt-4-1 = {
              "name" = "gpt-4.1";
            };
            gpt-4-1-mini = {
              "name" = "gpt-4.1-mini";
            };
            gpt-4-1-nano = {
              "name" = "gpt-4.1-nano";
            };
            gpt-4o = {
              "name" = "gpt-4o";
            };
            mistral-large-3 = {
              "name" = "mistral-large-3";
            };
            mistral-medium-3-1 = {
              "name" = "mistral-medium-3.1";
            };
            mistral-small-3-2-24b-instruct = {
              "name" = "mistral-small-3.2-24b-instruct";
            };
            magistral-medium-2506 = {
              "name" = "magistral-medium-2506";
            };
            codestral-2508 = {
              "name" = "codestral-2508";
            };
            grok-4 = {
              "name" = "grok-4";
            };
            grok-4-fast = {
              "name" = "grok-4-fast";
            };
            grok-code-fast-1 = {
              "name" = "grok-code-fast-1";
            };
            gemini-2-5-flash = {
              "name" = "gemini-2.5-flash";
            };
            gemini-3-pro = {
              "name" = "gemini-3-pro";
            };
            deepseek-r1-0528 = {
              "name" = "deepseek-r1-0528";
            };
            deepseek-v3-2 = {
              "name" = "deepseek-v3.2";
            };
            kimi-k2-instruct = {
              "name" = "kimi-k2-instruct";
            };
            kimi-k2-thinking = {
              "name" = "kimi-k2-thinking";
            };
            qwen3-coder = {
              "name" = "qwen3-coder";
            };
            qwen3-coder-flash = {
              "name" = "qwen3-coder-flash";
            };
            qwen3-coder-plus = {
              "name" = "qwen3-coder-plus";
            };
            llama-4-maverick = {
              "name" = "llama-4-maverick";
            };
            llama-4-scout = {
              "name" = "llama-4-scout";
            };
            sonar-pro = {
              "name" = "sonar-pro";
            };
            sonar-deep-research = {
              "name" = "sonar-deep-research";
            };
            claude-haiku-4-5 = {
              "name" = "claude-haiku-4-5";
            };
            claude-opus-4-5 = {
              "name" = "claude-opus-4-5";
            };
            claude-sonnet-4-5 = {
              "name" = "claude-sonnet-4-5";
            };
          };
        };
      };
    };
  };
}
