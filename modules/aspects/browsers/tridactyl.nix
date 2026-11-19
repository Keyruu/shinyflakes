{ ... }:
{
  den.aspects.browsers.tridactyl = {
    homeManager =
      { pkgs, lib, ... }:
      let
        # gh-pr-review <pr-url>: Claude review in a new tab of the "scratchpad"
        # zellij session. zellij only adds tabs to an attached session, so the
        # scratchpad window is shown (or spawned) first, then we wait for a client.
        ghPrReview = pkgs.writeShellApplication {
          name = "gh-pr-review";
          runtimeInputs = [
            pkgs.coreutils
            pkgs.gnugrep
          ];
          text = # bash
            ''
              url=$1
              [[ $url =~ ^https://github\.com/[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+/pull/[0-9]+$ ]] || {
                echo "gh-pr-review: not a GitHub PR URL: $url" >&2
                exit 2
              }
              # Every zellij action exits 0, even on a missing session; only an
              # attached session prints the CLIENT_ID header.
              attached() { zellij --session scratchpad action list-clients 2>/dev/null | grep -q '^CLIENT_ID'; }
              # shortcut: scratch-niri is niri-only; other WMs get an unmanaged kitty window.
              if command -v scratch-niri >/dev/null; then
                scratch-niri scratchpad kitty --class scratchpad zellij attach --create scratchpad
              elif ! attached; then
                kitty --class scratchpad --detach zellij attach --create scratchpad
              fi
              for _ in $(seq 1 50); do
                if attached; then
                  exec zellij --session scratchpad action new-tab --name "review ''${url#https://github.com/}" -- \
                    claude "Review the GitHub pull request $url. Fetch it with gh pr view and gh pr diff, then report findings ranked by severity."
                fi
                sleep 0.1
              done
              echo "gh-pr-review: no client attached to zellij session 'scratchpad'" >&2
              exit 1
            '';
        };
      in
      {
        # Sourced on every browser startup by the default TriStart autocmd
        # (source_quiet → ~/.config/tridactyl/tridactylrc). Values persist in
        # local storage and are re-asserted on each restart.
        # Tridactyl defaults already match these vimium-c defaults, no override
        # needed: f/F (hint), H/L (back/forward), J/K (tab prev/next), gt/gT,
        # g0/g$ (tab first/last), gu/gU (url up/root), gg/G (scroll top/bottom),
        # yy (yank url), p/P (clipboard open), r/R (reload/reloadhard),
        # m/` (marks), [[/]] (followpage), <</>> (tabmove), <a-m> (mute),
        # <a-p> (pin), <c-e>/<c-y> (scrollline).
        #
        # Not portable (tridactyl has no equivalent): v/V caret visual mode,
        # gf nextFrame, ^ visitPreviousTab, b/B bookmark vomnibar.
        xdg.configFile."tridactyl/tridactylrc".text = # vim
          ''
            " vimium-c default keymaps, mapped to tridactyl
            " scroll: vimium-c scrollStepSize 100
            bind j scrollpx 0 100
            bind k scrollpx 0 -100
            bind h scrollpx -100
            bind l scrollpx 100

            " half-page scroll (frees d/u from tabclose/undo)
            bind d scrollpage 0.5
            bind u scrollpage -0.5

            " tabs
            bind J tabnext
            bind K tabprev
            bind x tabclose
            bind X undo
            bind yt tabduplicate
            bind t tabopen
            bind T fillcmdline tab

            " vomnibar equivalents
            " needs native messenger; exclaim_quiet (!s) = silent, unlike !
            bind o exclaim_quiet vicinae vicinae://launch/@knoopx/vicinae-extension-firefox-0/omni
            bind O fillcmdline tabopen
            bind ge current_url open
            bind gE current_url tabopen

            " find mode
            bind / fillcmdline find
            bind n findnext 1
            bind N findnext -1

            " command line: vim-style history/completion navigation
            bind --mode=ex <C-k> ex.next_history_or_completion
            bind --mode=ex <C-n> ex.next_history_or_completion
            bind --mode=ex <C-j> ex.prev_history_or_completion
            bind --mode=ex <C-p> ex.prev_history_or_completion
            bind --mode=ex <C-y> ex.accept_line

            " hints
            bind yf hint -y

            " misc
            bind ? help
            bind i mode ignore
            bind gs viewsource
            bind W tabdetach
            bind zH scrollto 0 x
            bind zL scrollto 100 x
            bind <A-c> tabprev
            bind <A-s-c> tabnext

            " GitHub PR → Claude review tab in the scratchpad zellij session.
            " The regex keeps the URL shell-safe (exclaim runs via sh).
            bindurl ^https://github\.com/[^/]+/[^/]+/pull/\d+ gR composite js location.href.match(/^https:\/\/github\.com\/[\w.-]+\/[\w.-]+\/pull\/\d+/)[0] | exclaim_quiet ${lib.getExe ghPrReview}

            " settings
            set hintchars sadjklewcmpgh
            set searchengine https://kagi.com/search?q=

            " external editor (Ctrl-i in insert mode); dedicated app-id so
            " Umbriel can size/float the window independently of other terminals.
            set editorcmd kitty --class tridactyl-editor nvim
          '';

        programs.firefox.nativeMessagingHosts = [ pkgs.tridactyl-native ];
      };
  };
}
