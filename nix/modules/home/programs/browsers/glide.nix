{
  inputs,
  config,
  ...
}:
{
  imports = [
    inputs.glide.homeModules.default
  ];

  home.file.".glide-browser/native-messaging-hosts/com.1password.1password.json".text =
    builtins.toJSON
      {
        name = "com.1password.1password";
        description = "1Password BrowserSupport";
        path = "/run/wrappers/bin/1Password-BrowserSupport";
        type = "stdio";
        allowed_extensions = [
          "{0a75d802-9aed-41e7-8daa-24c067386e82}"
          "{25fc87fa-4d31-4fee-b5c1-c32a7844c063}"
          "{d634138d-c276-4fc8-924b-40a0ea21d284}"
        ];
      };

  programs.glide-browser = {
    enable = true;
    policies = {
      AutofillAddressEnabled = false;
      AutofillCreditCardEnabled = false;
      DontCheckDefaultBrowser = true;
      NoDefaultBookmarks = true;
      OfferToSaveLogins = false;
      TranslateEnabled = false;
      Preferences = {
        "browser.ctrlTab.sortByRecentlyUsed" = true;
        "toolkit.legacyUserProfileCustomizations.stylesheets" = true;
        "browser.toolbars.bookmarks.visibility" = "never";
      };
      ExtensionSettings =
        let
          mkExt = builtins.mapAttrs (
            _: pluginId: {
              install_url = "https://addons.mozilla.org/firefox/downloads/latest/${pluginId}/latest.xpi";
              installation_mode = "force_installed";
            }
          );
        in
        mkExt {
          "admin@2fas.com" = "2fas-two-factor-authentication";
          "uBlock0@raymondhill.net" = "ublock-origin";
          "{d634138d-c276-4fc8-924b-40a0ea21d284}" = "1password-x-password-manager";
          "{762f9885-5a13-4abd-9c77-433dcd38b8fd}" = "return-youtube-dislikes";
          "{3c078156-979c-498b-8990-85f7987dd929}" = "sidebery";
          "{81b74d53-9416-4fb3-afa2-ab46684b253b}" = "tabwrangler";
          "sponsorBlocker@ajay.app" = "sponsorblock";
        };
    };
  };

  xdg.configFile."glide/glide.ts".text = # ts
    ''
      /// <reference path="./glide.d.ts" />

      function scrollPage(tab_id: number, pixels: number, viewportFraction?: number) {
        return glide.content.execute((px: number, vf: number | null) => {
          function findScrollable(): Element {
            let el: Element | null = document.activeElement;
            while (el && el !== document.documentElement) {
              if (el.scrollHeight > el.clientHeight) {
                const style = getComputedStyle(el);
                if (/auto|scroll/.test(style.overflowY)) return el;
              }
              el = el.parentElement;
            }
            const candidates = document.querySelectorAll("*");
            let best: Element | null = null;
            let bestArea = 0;
            for (const c of candidates) {
              if (c.scrollHeight > c.clientHeight + 1) {
                const style = getComputedStyle(c);
                if (/auto|scroll/.test(style.overflowY)) {
                  const area = c.clientWidth * c.clientHeight;
                  if (area > bestArea) { best = c; bestArea = area; }
                }
              }
            }
            return best ?? document.scrollingElement ?? document.documentElement;
          }
          const delta = vf != null ? window.innerHeight * vf : px;
          findScrollable().scrollBy({ top: delta, behavior: "auto" });
        }, { tab_id, args: [pixels, viewportFraction ?? null] });
      }

      glide.keymaps.set("normal", "k", async () => {
        const tab = await glide.tabs.active();
        if (tab?.id) await scrollPage(tab.id, -200);
      }, { description: "Scroll up" });
      glide.keymaps.set("normal", "j", async () => {
        const tab = await glide.tabs.active();
        if (tab?.id) await scrollPage(tab.id, 200);
      }, { description: "Scroll down" });
      glide.keymaps.set("normal", "d", async () => {
        const tab = await glide.tabs.active();
        if (tab?.id) await scrollPage(tab.id, 0, 0.25);
      }, { description: "Scroll quarter page down" });
      glide.keymaps.set("normal", "u", async () => {
        const tab = await glide.tabs.active();
        if (tab?.id) await scrollPage(tab.id, 0, -0.25);
      }, { description: "Scroll quarter page up" });

      // History navigation (H/L instead of <C-h>/<C-l>)
      glide.keymaps.set("normal", "H", "back");
      glide.keymaps.set("normal", "L", "forward");

      // Tab switching (J/K instead of <C-j>/<C-k>)
      glide.keymaps.set("normal", "J", "tab_next");
      glide.keymaps.set("normal", "K", "tab_prev");

      // Tab management
      glide.keymaps.set("normal", "x", "tab_close");
      glide.keymaps.set("normal", "X", "tab_reopen");
      glide.keymaps.set("normal", "t", "tab_new");
      glide.keymaps.set("normal", "T", async () => {
        await glide.excmds.execute("commandline_show");
        await glide.keys.send("tab ");
      }, { description: "Search open tabs" });

      glide.keymaps.set("normal", "o", "tab_new");
      glide.keymaps.set("normal", "O", async () => {
        await glide.excmds.execute("commandline_show");
      }, { description: "Open URL in current tab" });

      glide.keymaps.set("normal", "r", "reload");
      glide.keymaps.set("normal", "R", "reload_hard");

      glide.keymaps.set("normal", "p", async () => {
        const text = await navigator.clipboard.readText();
        if (text) await glide.excmds.execute("tab_new " + text);
      }, { description: "Open clipboard URL in new tab" });
      glide.keymaps.set("normal", "P", async () => {
        const text = await navigator.clipboard.readText();
        const tab = await glide.tabs.active();
        if (text && tab?.id) await browser.tabs.update(tab.id, { url: text });
      }, { description: "Open clipboard URL in current tab" });

      glide.keymaps.set("command", "<C-j>", "commandline_focus_next");
      glide.keymaps.set("command", "<C-k>", "commandline_focus_back");

      glide.keymaps.set("normal", "<leader><leader>", "omni");
      glide.keymaps.set("normal", "<leader>c", "config_reload");
      glide.keymaps.set("normal", "<leader>e", "editor");

      glide.excmds.create({ name: "editor", description: "Edit focused textarea in external editor" }, async () => {
        const tab = await glide.tabs.active();
        if (!tab?.id) return;

        const result = await glide.content.execute(() => {
          const el = document.activeElement as HTMLElement | null;
          if (!el) return null;
          const isEditable = el.isContentEditable;
          const hasValue = "value" in el;
          if (!isEditable && !hasValue) return null;
          const rect = el.getBoundingClientRect();
          return {
            text: hasValue ? (el as HTMLTextAreaElement).value : el.innerText,
            contentEditable: isEditable,
            x: Math.round(rect.x + window.screenX),
            y: Math.round(rect.y + window.screenY),
            w: Math.round(rect.width),
            h: Math.round(rect.height),
          };
        }, { tab_id: tab.id });

        if (!result) return;

        const tmpfile = `/tmp/glide-editor-''${Date.now()}.md`;
        await glide.fs.write(tmpfile, result.text);

        const foot = glide.process.execute("footclient", [
          "--app-id", "glide-editor",
          "--title", "Glide Editor",
          "nvim", "--clean", "-c", "set laststatus=0 noshowcmd noruler | hi Normal guibg=NONE ctermbg=NONE | hi NonText guibg=NONE ctermbg=NONE", tmpfile,
        ], { check_exit_code: false });

        await new Promise(r => setTimeout(r, 100));

        const wins = await glide.process.execute("niri", ["msg", "-j", "windows"]);
        const windows = JSON.parse(await wins.stdout.text());
        const editor = windows.find((w: { app_id: string }) => w.app_id === "glide-editor");

        if (editor) {
          await glide.process.execute("niri", [
            "msg", "action", "move-floating-window", "--id", String(editor.id),
            "-x", String(result.x + 50), "-y", String(result.y + 50)
          ]);
          await glide.process.execute("niri", [
            "msg", "action", "set-window-width", 
            "--id", String(editor.id), String(Math.max(result.w, 50))
          ]);
          await glide.process.execute("niri", [
            "msg", "action", "set-window-height", 
            "--id", String(editor.id), String(Math.max(result.h, 100))
          ]);
        }

        await foot;

        const edited = await glide.fs.read(tmpfile, "utf8");
        await glide.content.execute((newText: string, wasContentEditable: boolean) => {
          const el = document.activeElement as HTMLElement | null;
          if (!el) return;
          if (wasContentEditable || el.isContentEditable) {
            el.focus();
            document.execCommand("selectAll");
            document.execCommand("insertText", false, newText);
          } else if ("value" in el) {
            (el as HTMLTextAreaElement).value = newText;
            el.dispatchEvent(new Event("input", { bubbles: true }));
          }
        }, { tab_id: tab.id, args: [edited, result.contentEditable] });
      });


      glide.excmds.create({ name: "omni", description: "Search tabs, bookmarks, history, or the web" }, async () => {
        const [tabs, bookmarks, history, containers] = await Promise.all([
          browser.tabs.query({}),
          browser.bookmarks.search({}),
          browser.history.search({ text: "", maxResults: 500 }),
          browser.contextualIdentities.query({}),
        ]);

        const containerMap = new Map(containers.map(c => [c.cookieStoreId, c]));

        const options: Parameters<typeof glide.commandline.show>[0]["options"] = [
          ...tabs.filter(t => t.id != null).map(t => {
            const container = t.cookieStoreId ? containerMap.get(t.cookieStoreId) : undefined;
            const prefix = t.active ? "▶" : "🗂️";
            const suffix = container ? ` [''${container.name}]` : "";
            return {
              label: `''${prefix} ''${t.title}''${suffix}`,
              description: t.url ?? "",
              execute() { browser.tabs.update(t.id!, { active: true }); },
            };
          }),
          ...bookmarks.filter(bm => bm.url).map(bm => ({
            label: `⭐ ''${bm.title}`,
            description: bm.url!,
            execute() { browser.tabs.create({ url: bm.url! }); },
          })),
          ...history.filter(h => h.url).map(h => ({
            label: `🕐 ''${h.title}`,
            description: h.url!,
            execute() { browser.tabs.create({ url: h.url! }); },
          })),
          {
            label: "🔍 Search the web",
            description: "Open a Kagi search",
            matches() { return true; },
            execute({ input }) {
              if (!input) return;
              const isUrl = /^https?:\/\//i.test(input)
                || /^[a-zA-Z0-9-]+(\.[a-zA-Z0-9-]+)*\.[a-zA-Z]{2,}(\/|$)/.test(input);
              if (isUrl) {
                const url = input.startsWith("http") ? input : `https://''${input}`;
                browser.tabs.create({ url });
              } else {
                const q = encodeURIComponent(input);
                browser.tabs.create({ url: `https://kagi.com/search?q=''${q}` });
              }
            },
          },
        ];

        await glide.commandline.show({ title: "Open", options });
      });

      glide.o.native_tabs = "hide";
      glide.styles.add(css`
        :root:has(.tabbrowser-tab[selected].identity-color-blue) :is(#nav-bar) {
          background-color: color-mix(in srgb, #37adff 15%, transparent) !important;
        }
        :root:has(.tabbrowser-tab[selected].identity-color-orange) :is(#nav-bar) {
          background-color: color-mix(in srgb, #ff9f00 15%, transparent) !important;
        }

        #sidebar-box #sidebar-header { display: none !important; }

        /* Autohide sidebar (Sidebery only)
         * https://github.com/MrOtherGuy/firefox-csshacks/blob/master/chrome/autohide_sidebar.css */
        :where(#main-window) #browser {
          --uc-sidebar-width: 36px;
          --uc-sidebar-hover-width: 210px;
        }
        #main-window[sizemode="fullscreen"] #browser {
          --uc-sidebar-width: 1px;
        }
        #sidebar-box {
          --uc-autohide-sidebar-delay: 600ms;
          --uc-autohide-transition-duration: 115ms;
          --uc-autohide-transition-type: linear;
          --browser-area-z-index-sidebar: 3;
          position: relative;
          min-width: var(--uc-sidebar-width) !important;
          width: var(--uc-sidebar-width) !important;
          max-width: var(--uc-sidebar-width) !important;
          z-index: var(--browser-area-z-index-sidebar, 3);
          background-color: inherit;
          direction: ltr;
        }
        #sidebar-box:is([positionend],[sidebar-positionend]):not(:-moz-locale-dir(rtl)) {
          direction: rtl;
        }
        .sidebar-browser-stack {
          background: inherit;
        }
        #sidebar-splitter { display: none; }
        #sidebar-header {
          overflow: hidden;
          color: var(--chrome-color, inherit) !important;
          padding-inline: 0 !important;
        }
        #sidebar-header::before,
        #sidebar-header::after {
          content: "";
          display: flex;
          padding-left: 8px;
        }
        #sidebar-header,
        #sidebar {
          transition: min-width var(--uc-autohide-transition-duration) var(--uc-autohide-transition-type) var(--uc-autohide-sidebar-delay) !important;
          min-width: var(--uc-sidebar-width) !important;
          will-change: min-width;
          direction: ltr;
        }
        #sidebar-header:-moz-locale-dir(rtl),
        #sidebar:-moz-locale-dir(rtl) {
          direction: rtl;
        }
        #sidebar-box:hover > #sidebar-header,
        #sidebar-box:hover > #sidebar,
        #sidebar-box:hover > .sidebar-browser-stack > #sidebar {
          min-width: var(--uc-sidebar-hover-width) !important;
          transition-delay: 0ms !important;
        }
        .sidebar-panel {
          background-color: transparent !important;
          color: var(--newtab-text-primary-color) !important;
        }
        .sidebar-panel #search-box {
          -moz-appearance: none !important;
          background-color: rgba(249,249,250,0.1) !important;
          color: inherit !important;
        }
        #sidebar,
        #sidebar-header {
          background-color: inherit !important;
          border-inline: 1px solid rgb(80,80,80);
          border-inline-width: 0px 1px;
        }
        #sidebar-box:not([positionend],[sidebar-positionend]) > :-moz-locale-dir(rtl),
        #sidebar-box:is([positionend],[sidebar-positionend]) > * {
          border-inline-width: 1px 0px;
        }
        @media -moz-pref("sidebar.revamp") {
          #sidebar, #sidebar-header { border-style: none; }
          #sidebar-box { padding: 0 !important; }
        }
        #sidebar-box:not([positionend],[sidebar-positionend]):hover ~ #appcontent #statuspanel {
          inset-inline: auto 0px !important;
        }
        #sidebar-box:not([positionend],[sidebar-positionend]):hover ~ #appcontent #statuspanel-label {
          margin-inline: 0px !important;
          border-left-style: solid !important;
        }
      `);
    '';
}
