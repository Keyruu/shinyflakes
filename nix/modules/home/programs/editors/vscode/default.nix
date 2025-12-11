_:
{
  programs.vscode = {
    enable = true;
    mutableExtensionsDir = true;

    profiles.default = {
      enableUpdateCheck = false;
      enableExtensionUpdateCheck = true;
      userSettings = {
        "files.exclude" = {
          "**/.project" = true;
          "**/.settings" = true;
          "**/.classpath" = true;
          "**/.factorypath" = true;
        };
        "emmet.includeLanguages" = {
          "rust" = "html";
          "*.rs" = "html";
        };
        "tailwindCSS.includeLanguages" = {
          "rust" = "html";
          "*.rs" = "html";
          "templ" = "html";
        };
        "tailwindCSS.experimental.classRegex" = [
          "class\\s*:\\s*\"([^\"]*)"
        ];
        "files.associations" = {
          "*.rs" = "rust";
        };
        "editor.quickSuggestions" = {
          "other" = "on";
          "comments" = "on";
          "strings" = true;
        };
        "css.validate" = false;
        # "workbench.colorTheme" = "Ayu Dark Bordered";
        "editor.tabSize" = 2;
        "svelte.enable-ts-plugin" = true;
        "editor.autoIndent" = "advanced";
        "git.autofetch" = true;
        "editor.cursorSmoothCaretAnimation" = "on";
        "editor.cursorBlinking" = "phase";
        "editor.accessibilitySupport" = "off";
        "vsintellicode.modify.editor.suggestSelection" = "automaticallyOverrodeDefaultValue";
        "editor.suggestSelection" = "first";
        "security.workspace.trust.untrustedFiles" = "open";
        "redhat.telemetry.enabled" = false;
        "workbench.iconTheme" = "material-icon-theme";
        "[yaml]" = {
          "editor.defaultFormatter" = "redhat.vscode-yaml";
        };
        "editor.minimap.enabled" = false;
        "git.confirmSync" = false;
        "javascript.updateImportsOnFileMove.enabled" = "always";
        "[typescriptreact]" = {
          "editor.defaultFormatter" = "vscode.typescript-language-features";
        };
        "[json]" = {
          "editor.defaultFormatter" = "vscode.json-language-features";
        };
        "[javascript]" = {
          "editor.defaultFormatter" = "vscode.typescript-language-features";
        };
        "[typescript]" = {
          "editor.defaultFormatter" = "vscode.typescript-language-features";
        };
        "typescript.updateImportsOnFileMove.enabled" = "always";
        "explorer.confirmDragAndDrop" = false;
        "[css]" = {
          "editor.defaultFormatter" = "vscode.css-language-features";
        };
        "[dockercompose]" = {
          "editor.defaultFormatter" = "esbenp.prettier-vscode";
        };
        "go.toolsManagement.autoUpdate" = true;
        "[svelte]" = {
          "editor.defaultFormatter" = "svelte.svelte-vscode";
        };
        "window.nativeTabs" = true;
        "[rust]" = {
          "editor.formatOnSave" = true;
          "editor.defaultFormatter" = "rust-lang.rust-analyzer";
        };
        "editor.formatOnSave" = true;
        "files.autoSave" = "onFocusChange";
        "files.autoSaveDelay" = 500;
        "[jsonc]" = {
          "editor.defaultFormatter" = "vscode.json-language-features";
        };
        "[html]" = {
          "editor.defaultFormatter" = "esbenp.prettier-vscode";
        };
        "yaml.format.bracketSpacing" = false;
        "prettier.enable" = false;
        "vs-kubernetes" = {
          "vs-kubernetes.crd-code-completion" = "disabled";
          "vs-kubernetes.ignore-recommendations" = true;
          "vs-kubernetes.minikube-show-information-expiration" = "2025-08-26T08:13:22.604Z";
        };
        "git.enableSmartCommit" = true;
        "remote.SSH.defaultExtensions" = [
          "gitpod.gitpod-remote-ssh"
        ];
        "editor.stickyScroll.enabled" = true;
        "workbench.startupEditor" = "none";
        "terminal.integrated.defaultProfile.windows" = "PowerShell";
        "editor.lineNumbers" = "relative";
        "quarkus.tools.alwaysShowWelcomePage" = false;
        # "editor.fontFamily" = "JetBrainsMonoNL Nerd Font; monospace";
        # "editor.fontSize" = 13;
        # "debug.console.fontSize" = 13;
        # "terminal.integrated.fontSize" = 13;
        "lldb.suppressUpdateNotifications" = true;
        "quarkus.tools.debug.terminateProcessOnExit" = "Always terminate";
        "gitlens.codeLens.enabled" = false;
        "debug.onTaskErrors" = "debugAnyway";
        "vetur.format.defaultFormatterOptions" = {
          "js-beautify-html" = {
            "wrap_attributes" = "force-expand-multiline";
          };
          "prettyhtml" = {
            "printWidth" = 100;
            "singleQuote" = false;
            "wrapAttributes" = false;
            "sortAttributes" = false;
          };
        };
        "gitlens.views.commits.avatars" = false;
        "gitlens.views.showRelativeDateMarkers" = false;
        "liveServer.settings.donotVerifyTags" = true;
        "qute.validation.enabled" = true;
        "[python]" = {
          "editor.formatOnType" = true;
          "editor.defaultFormatter" = "ms-python.python";
        };
        "git.openRepositoryInParentFolders" = "always";
        "gitlens.views.branches.branches.layout" = "list";
        "editor.guides.bracketPairs" = true;
        "java.saveActions.organizeImports" = true;
        "editor.codeActionsOnSave" = {
          "source.organizeImports" = "explicit";
        };
        "workbench.editor.labelFormat" = "short";
        "editor.inlineSuggest.enabled" = true;
        "yaml.customTags" = [
          "{{ scalar"
        ];
        "yaml.schemas" = {
          "kubernetes" = [
            "templates/*.yaml"
          ];
          "https://www.dashbuilder.org/schemas/0.1/dashbuilder.json" = [
            "**/*.dash.yml"
            "**/*.dash.yaml"
            "**/*.dash.json"
          ];
        };
        "tailwindCSS.experimental.configFile" = null;
        "supermaven.enable" = {
          "*" = true;
        };
        "vetur.format.defaultFormatter.ts" = "none";
        "vetur.format.defaultFormatter.js" = "none";
        "roo-cline.allowedCommands" = [
          "tsc"
          "git log"
          "git diff"
          "git show"
          "pnpm install"
          "pnpm test"
        ];
        "nix.enableLanguageServer" = true;
        "nix.serverSettings" = {
          "nixpkgs" = {
            "expr" = "import <nixpkgs> {}";
          };
          "formatting" = {
            "command" = "nixfmt";
          };
          "options" = {
            "nixos" = {
              "expr" = "(builtins.getFlake \"/home/lucas/shinyflakes\").nixosConfigurations.sleipnir.options";
            };
            "home-manager" = {
              "expr" =
                "(builtins.getFlake \"/home/lucas/shinyflakes\").homeConfigurations.\"lucas.rott@stern\".options";
            };
            "nix-darwin" = {
              "expr" = "(builtins.getFlake \"/home/lucas/shinyflakes\").darwinConfigurations.stern.options";
            };
          };
        };
        "nix.serverPath" = "nixd";
        "evenBetterToml.schema.enabled" = false;
        "evenBetterToml.taplo.bundled" = false;
        "makefile.configureOnOpen" = true;
        "editor.insertSpaces" = false;
        "eslint.format.enable" = true;
      };
    };
  };
}
