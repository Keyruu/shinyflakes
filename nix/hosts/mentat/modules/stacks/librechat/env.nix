{ config, ... }:
{
  sops.secrets = {
    anthropicKey.owner = "root";
    geminiKey.owner = "root";
    openaiKey.owner = "root";
    openrouterKey.owner = "root";
    scalewayKey.owner = "root";
    mistralKey.owner = "root";
    librechatCredsKey.owner = "root";
    librechatCredsIv.owner = "root";
    librechatJwtSecret.owner = "root";
    librechatJwtRefreshSecret.owner = "root";
    librechatMeiliMasterKey.owner = "root";
    librechatPostgresPassword.owner = "root";
  };

  sops.templates."librechat.env" = {
    restartUnits = [ "librechat-api.service" ];
    content = # sh
      ''
        #=====================================================================#
        #                       LibreChat Configuration                       #
        #=====================================================================#
        # Please refer to the reference documentation for assistance          #
        # with configuring your LibreChat environment.                        #
        #                                                                     #
        # https://www.librechat.ai/docs/configuration/dotenv                  #
        #=====================================================================#

        #==================================================#
        #               Server Configuration               #
        #==================================================#

        HOST=0.0.0.0
        PORT=3080

        MONGO_URI=mongodb://mongodb:27017/LibreChat

        DOMAIN_CLIENT=http://localhost:3080
        DOMAIN_SERVER=http://localhost:3080

        NO_INDEX=true
        # Use the address that is at most n number of hops away from the Express application.
        # req.socket.remoteAddress is the first hop, and the rest are looked for in the X-Forwarded-For header from right to left.
        # A value of 0 means that the first untrusted address would be req.socket.remoteAddress, i.e. there is no reverse proxy.
        # Defaulted to 1.
        TRUST_PROXY=1

        POSTGRES_PASSWORD=${config.sops.placeholder.librechatPostgresPassword}

        #===============#
        # JSON Logging  #
        #===============#

        # Use when process console logs in cloud deployment like GCP/AWS
        CONSOLE_JSON=false

        #===============#
        # Debug Logging #
        #===============#

        DEBUG_LOGGING=true
        DEBUG_CONSOLE=false

        #=============#
        # Permissions #
        #=============#

        # UID=1000
        # GID=1000

        #===============#
        # Configuration #
        #===============#
        # Use an absolute path, a relative path, or a URL

        # CONFIG_PATH="/alternative/path/to/librechat.yaml"

        #===================================================#
        #                     Endpoints                     #
        #===================================================#

        # ENDPOINTS=openAI,assistants,azureOpenAI,google,gptPlugins,anthropic

        PROXY=

        #===================================#
        # Known Endpoints - librechat.yaml  #
        #===================================#
        # https://www.librechat.ai/docs/configuration/librechat_yaml/ai_endpoints

        MISTRAL_API_KEY=${config.sops.placeholder.mistralKey}
        OPENROUTER_KEY=${config.sops.placeholder.openrouterKey}
        SCALEWAY_KEY=${config.sops.placeholder.scalewayKey}

        #============#
        # Anthropic  #
        #============#

        ANTHROPIC_API_KEY=${config.sops.placeholder.anthropicKey}
        ANTHROPIC_MODELS=claude-opus-4-5,claude-sonnet-4-5,claude-haiku-4-5,claude-opus-4-1,claude-sonnet-4-0
        # ANTHROPIC_REVERSE_PROXY=

        #============#
        # Google     #
        #============#

        GOOGLE_KEY=${config.sops.placeholder.geminiKey}

        # Gemini API (AI Studio)
        GOOGLE_MODELS=gemini-3-pro-preview,gemini-2.5-flash,gemini-2.5-pro

        #============#
        # OpenAI     #
        #============#

        OPENAI_API_KEY=${config.sops.placeholder.openaiKey}
        OPENAI_MODELS=gpt-5.1-2025-11-13,gpt-5-mini-2025-08-07,gpt-5-nano-2025-08-07,gpt-5-pro-2025-10-06,gpt-5-2025-08-07,gpt-4.1-2025-04-14

        DEBUG_OPENAI=false

        DEBUG_PLUGINS=true

        CREDS_KEY=${config.sops.placeholder.librechatCredsKey}
        CREDS_IV=${config.sops.placeholder.librechatCredsIv}

        #==================================================#
        #                      Search                      #
        #==================================================#

        SEARCH=true
        MEILI_NO_ANALYTICS=true
        MEILI_HOST=http://meiliesearch:7700
        MEILI_MASTER_KEY=${config.sops.placeholder.librechatMeiliMasterKey}

        # Optional: Disable indexing, useful in a multi-node setup
        # where only one instance should perform an index sync.
        # MEILI_NO_SYNC=true

        #==================================================#
        #          Speech to Text & Text to Speech         #
        #==================================================#

        STT_API_KEY=
        TTS_API_KEY=

        #==================================================#
        #                        RAG                       #
        #==================================================#
        # More info: https://www.librechat.ai/docs/configuration/rag_api

        # RAG_OPENAI_BASEURL=
        # RAG_OPENAI_API_KEY=
        # RAG_USE_FULL_CONTEXT=
        # EMBEDDINGS_PROVIDER=openai
        # EMBEDDINGS_MODEL=text-embedding-3-small

        #===================================================#
        #                    User System                    #
        #===================================================#

        #========================#
        # Moderation             #
        #========================#

        OPENAI_MODERATION=false
        OPENAI_MODERATION_API_KEY=
        # OPENAI_MODERATION_REVERSE_PROXY=

        BAN_VIOLATIONS=true
        BAN_DURATION=1000 * 60 * 60 * 2
        BAN_INTERVAL=20

        LOGIN_VIOLATION_SCORE=1
        REGISTRATION_VIOLATION_SCORE=1
        CONCURRENT_VIOLATION_SCORE=1
        MESSAGE_VIOLATION_SCORE=1
        NON_BROWSER_VIOLATION_SCORE=37ffd5c0f9aa895dade1bc0dadd307e420

        LOGIN_MAX=7
        LOGIN_WINDOW=5
        REGISTER_MAX=5
        REGISTER_WINDOW=60

        LIMIT_CONCURRENT_MESSAGES=true
        CONCURRENT_MESSAGE_MAX=2

        LIMIT_MESSAGE_IP=true
        MESSAGE_IP_MAX=40
        MESSAGE_IP_WINDOW=1

        LIMIT_MESSAGE_USER=false
        MESSAGE_USER_MAX=40
        MESSAGE_USER_WINDOW=1

        ILLEGAL_MODEL_REQ_SCORE=5

        #========================#
        # Balance                #
        #========================#

        # CHECK_BALANCE=false
        # START_BALANCE=20000 # note: the number of tokens that will be credited after registration.

        #========================#
        # Registration and Login #
        #========================#

        ALLOW_EMAIL_LOGIN=true
        ALLOW_REGISTRATION=true
        ALLOW_SOCIAL_LOGIN=false
        ALLOW_SOCIAL_REGISTRATION=false
        ALLOW_PASSWORD_RESET=false
        # ALLOW_ACCOUNT_DELETION=true # note: enabled by default if omitted/commented out
        ALLOW_UNVERIFIED_EMAIL_LOGIN=true

        SESSION_EXPIRY=1000 * 60 * 15
        REFRESH_TOKEN_EXPIRY=(1000 * 60 * 60 * 24) * 7

        JWT_SECRET=${config.sops.placeholder.librechatJwtSecret}
        JWT_REFRESH_SECRET=${config.sops.placeholder.librechatJwtRefreshSecret}

        #===================================================#
        #                        UI                         #
        #===================================================#

        APP_TITLE=LibreChat
        # CUSTOM_FOOTER="My custom footer"
        HELP_AND_FAQ_URL=https://librechat.ai

        # SHOW_BIRTHDAY_ICON=true

        # Google tag manager id
        #ANALYTICS_GTM_ID=user provided google tag manager id
      '';
  };
}
