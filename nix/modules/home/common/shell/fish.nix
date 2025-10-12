{ pkgs, config, ... }:
{
  programs.man.generateCaches = false;

  programs.fish = {
    enable = true;

    functions = {
      starship_transient_rprompt_func = "starship module time";
    };

    shellInit =
      # fish
      ''
        switch (uname)
          case Darwin
            starship init fish --print-full-init | source
            eval "$(/opt/homebrew/bin/brew shellenv)"
            fish_add_path $HOME/.krew
            fish_add_path $HOME/.cargo/bin
            fish_add_path $HOME/Library/Application\ Support/JetBrains/Toolbox/scripts/
            fish_add_path $HOME/Library/Application\ Support/Coursier/bin
            fish_add_path $HOME/.orbstack/bin
            set -x PNPM_HOME $HOME/.pnpm-bin
            source $HOME/.local/bin/env.fish
          case Linux
            starship init fish | source
        end

        alias opencode-sst "bun run $HOME/tmp/opencode/packages/opencode/src/index.ts"
        fish_add_path $HOME/.pnpm-bin
        fish_add_path $HOME/.local/bin

        fish_vi_key_bindings
        bind --mode insert --sets-mode default \;\; repaint
        bind --mode insert \cj history-search-forward
        bind --mode insert \ck history-search-backward
        bind --mode insert \cl forward-char
        bind --mode insert \ch backward-char

        set -U fish_greeting

        set -x KUBECONFIG (string join ":" $HOME/.kube/*.yaml)

        if test -f "${config.sops.secrets.shellEnv.path}"
          while read -l line
            if string match -q -v '^#' "$line" && string match -q '*=*' "$line"
              set -gx (string split -m1 '=' "$line")
            end
          end < "${config.sops.secrets.shellEnv.path}"
        else
          echo "Warning: SOPS secrets file not found at ${config.sops.secrets.shellEnv.path}" >&2
        end
      '';

    shellInitLast =
      # fish
      ''
        # function is_inside_neovim
        #   # Check if NVIM environment variable is set
        #   if test -n "$NVIM"
        #     return 0  # Inside Neovim
        #   end
        #   return 1  # Not inside Neovim
        # end
        # # Call enable_transience only if not inside Neovim terminal
        # if not is_inside_neovim
        #   enable_transience
        # end
      '';
  };
}
