{ pkgs, config, ... }:
{
  programs.man.generateCaches = false;

  programs.fish = {
    enable = true;

    plugins = [
      {
        name = "fish-ai";
        src = pkgs.fetchFromGitHub {
          owner = "Realiserad";
          repo = "fish-ai";
          rev = "v2.3.1";
          hash = "sha256-bgFvzjX/TphyoAz4X9Xsux8zK/N9QeBY04d9q5z8lwc=";
        };
      }
    ];

    functions = {
      starship_transient_rprompt_func = "starship module time";
    };

    shellInit =
      # fish
      ''
        starship init fish | source

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

        function last_history_item
          echo $history[1]
        end
        abbr -a !! --position anywhere --function last_history_item
      '';
  };
}
