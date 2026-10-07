{ ... }:
{
  den.aspects.browsers.tridactyl = {
    homeManager =
      { pkgs, ... }:
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
            bind j scrollpx 100
            bind k scrollpx -100
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
            bind o exclaim_quiet vicinae vicinae://launch/@knoopx/firefox/omni
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

            " settings
            set hintchars sadjklewcmpgh
            set searchengine https://kagi.com/search?q=

            " external editor (Ctrl-i in insert mode); dedicated app-id so
            " niri can size/float the window (see window-rules.kdl)
            set editorcmd footclient --app-id tridactyl-editor nvim
          '';

        programs.firefox.nativeMessagingHosts = [ pkgs.tridactyl-native ];
      };
  };
}
