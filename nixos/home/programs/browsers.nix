{...}: {
  programs = {
    chromium = {
      enable = true;
      commandLineArgs = ["--enable-features=TouchpadOverscrollHistoryNavigation"];
      extensions = [
        # {id = "";}  // extension id, query from chrome web store
      ];
    };

    firefox = {
      enable = true;
      profiles.lucas = {
        userChrome = ''
          #TabsToolbar{ visibility: collapse !important }
          /* Source file https://github.com/MrOtherGuy/firefox-csshacks/tree/master/chrome/hide_tabs_toolbar.css made available under Mozilla Public License v. 2.0
          See the above repository for updates as well as full license text. */

          /* Hides tabs toolbar */
          /* For OSX use hide_tabs_toolbar_osx.css instead */

          /* Note, if you have either native titlebar or menubar enabled, then you don't really need this style.
           * In those cases you can just use: #TabsToolbar{ visibility: collapse !important }
           */

          /* IMPORTANT */
          /*
          Get window_control_placeholder_support.css
          Window controls will be all wrong without it
          */

          :root[tabsintitlebar]{ --uc-toolbar-height: 40px; }
          :root[tabsintitlebar][uidensity="compact"]{ --uc-toolbar-height: 32px }
#titlebar{
            will-change: unset !important;
            transition: none !important;
            opacity: 1 !important;
          }
#TabsToolbar{ visibility: collapse !important }

          :root[sizemode="fullscreen"] #TabsToolbar > :is(#window-controls,.titlebar-buttonbox-container){
            visibility: visible !important;
            z-index: 2;
          }

          :root:not([inFullscreen]) #nav-bar{
            margin-top: calc(0px - var(--uc-toolbar-height,0px));
          }

          :root[tabsintitlebar] #toolbar-menubar[autohide="true"]{
            min-height: unset !important;
            height: var(--uc-toolbar-height,0px) !important;
            position: relative;
          }

#toolbar-menubar[autohide="false"]{
            margin-bottom: var(--uc-toolbar-height,0px)
          }

          :root[tabsintitlebar] #toolbar-menubar[autohide="true"] #main-menubar{
            flex-grow: 1;
            align-items: stretch;
            background-attachment: scroll, fixed, fixed;
            background-position: 0 0, var(--lwt-background-alignment), right top;
            background-repeat: repeat-x, var(--lwt-background-tiling), no-repeat;
            background-size: auto 100%, var(--lwt-background-size, auto auto), auto auto;
            padding-right: 20px;
          }
          :root[tabsintitlebar] #toolbar-menubar[autohide="true"]:not([inactive]) #main-menubar{
            background-color: var(--lwt-accent-color);
            background-image: linear-gradient(var(--toolbar-bgcolor,--toolbar-non-lwt-bgcolor),var(--toolbar-bgcolor,--toolbar-non-lwt-bgcolor)), var(--lwt-additional-images,none), var(--lwt-header-image, none);
            mask-image: linear-gradient(to left, transparent, black 20px);
          }

#toolbar-menubar:not([inactive]){ z-index: 2 }
#toolbar-menubar[autohide="true"][inactive] > #menubar-items {
            opacity: 0;
            pointer-events: none;
            margin-left: var(--uc-window-drag-space-pre,0px)
          }

          /* Source file https://github.com/MrOtherGuy/firefox-csshacks/tree/master/chrome/window_control_placeholder_support.css made available under Mozilla Public License v. 2.0
          See the above repository for updates as well as full license text. */

          /* Creates placeholders for window controls */
          /* This is a supporting file used by other stylesheets */

          /* This stylesheet is pretty much unnecessary if window titlebar is enabled */

          /* This file should preferably be imported before other stylesheets */

          /* Defaults for window controls on RIGHT side of the window */
          /* Modify these values to match your preferences */
          :root:is([tabsintitlebar], [sizemode="fullscreen"]) {
            --uc-window-control-width: 138px; /* Space reserved for window controls (Win10) */
            /* Extra space reserved on both sides of the nav-bar to be able to drag the window */
            --uc-window-drag-space-pre: 30px; /* left side*/
            --uc-window-drag-space-post: 30px; /* right side*/
          }

          :root:is([tabsintitlebar][sizemode="maximized"], [sizemode="fullscreen"]) {
            --uc-window-drag-space-pre: 0px; /* Remove pre space */
          }

          @media  (-moz-platform: windows-win7),
                  (-moz-platform: windows-win8){
            :root:is([tabsintitlebar], [sizemode="fullscreen"]) {
              --uc-window-control-width: 105px;
            }
          }

          @media (-moz-gtk-csd-available) {
            :root:is([tabsintitlebar],[sizemode="fullscreen"]) {
              --uc-window-control-width: 84px;
            }
          }
          @media (-moz-platform: macos){
            :root:is([tabsintitlebar]) {
              --uc-window-control-width: 72px;
            }
            :root:is([tabsintitlebar][sizemode="fullscreen"]) {
              --uc-window-control-width: 0;
            }
          }

          .titlebar-buttonbox, #window-controls{ color: var(--toolbar-color) }
          :root[sizemode="fullscreen"] .titlebar-buttonbox-container{ display: none }
          :root[sizemode="fullscreen"] #navigator-toolbox { position: relative; }

          :root[sizemode="fullscreen"] #TabsToolbar > .titlebar-buttonbox-container:last-child,
          :root[sizemode="fullscreen"] #window-controls{
            position: absolute;
            display: flex;
            top: 0;
            right:0;
            height: 40px;
          }

          :root[sizemode="fullscreen"] #TabsToolbar > .titlebar-buttonbox-container:last-child,
          :root[uidensity="compact"][sizemode="fullscreen"] #window-controls{ height: 32px }

#nav-bar{
            border-inline: var(--uc-window-drag-space-pre,0px) solid transparent;
            border-inline-style: solid !important;
            border-right-width: calc(var(--uc-window-control-width,0px) + var(--uc-window-drag-space-post,0px));
            background-clip: border-box !important;
          }

          /* Rules for window controls on left layout */
          @media (-moz-bool-pref: "userchrome.force-window-controls-on-left.enabled"),
                 (-moz-gtk-csd-reversed-placement),
                 (-moz-platform: macos){
            :root[tabsintitlebar="true"] #nav-bar{
              border-inline-width: calc(var(--uc-window-control-width,0px) + var(--uc-window-drag-space-post,0px)) var(--uc-window-drag-space-pre,0px)
            }
            :root[sizemode="fullscreen"] #TabsToolbar > .titlebar-buttonbox-container:last-child,
            :root[sizemode="fullscreen"] #window-controls{ right: unset }
          }
          @media (-moz-bool-pref: "userchrome.force-window-controls-on-left.enabled"){
            .titlebar-buttonbox-container{
              order: -1 !important;
            }
            .titlebar-buttonbox{
              flex-direction: row-reverse;
            }
          }

          /* This pref can be used to force window controls on left even if that is not normal behavior on your OS */
          @supports -moz-bool-pref("userchrome.force-window-controls-on-left.enabled"){
            :root[tabsintitlebar="true"] #nav-bar{
              border-inline-width: calc(var(--uc-window-control-width,0px) + var(--uc-window-drag-space-post,0px)) var(--uc-window-drag-space-pre,0px)
            }
            :root[sizemode="fullscreen"] #TabsToolbar > .titlebar-buttonbox-container:last-child,
            :root[sizemode="fullscreen"] #window-controls{ right: unset; }
            .titlebar-buttonbox-container{
              order: -1 !important;
            }
            .titlebar-buttonbox{
              flex-direction: row-reverse;
            }
          }
        '';
      };
    };
  };
}
