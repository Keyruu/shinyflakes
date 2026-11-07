import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs.Common
import qs.Services
import qs.Widgets

// Standalone window switcher for Umbriel.
//
// The overlay is a layer-shell surface of its own (namespace "dms:window-switcher"),
// so it is not a launcher plugin and does not need the DMS launcher.
//
// IPC (umbriel keybind): `dms ipc call window-switcher open|close|toggle`
Item {
  id: root

  property var pluginService: null
  property string pluginId: "windowSwitcher"

  readonly property var log: Log.scoped("WindowSwitcher")

  // Umbriel is the only compositor whose window list we can query here.
  readonly property bool supported: CompositorService.isUmbriel

  property bool opened: false
  property bool overlayWasActive: false
  property string pendingFocusId: ""
  property string filter: ""
  property int selectedIndex: 0
  property string restoreWindowId: ""

  // Windows sorted by workspace, then by their place in the layout.
  readonly property var windows: {
    const list = UmbrielService.windows || [];
    const workspaceOrder = {};
    for (const ws of (UmbrielService.workspaces || []))
      workspaceOrder[ws.id] = ws.index ?? 0;

    return list.slice().sort((a, b) => {
      const aw = workspaceOrder[a.workspace] ?? 0;
      const bw = workspaceOrder[b.workspace] ?? 0;
      if (aw !== bw)
        return aw - bw;
      return (a.column ?? -1) - (b.column ?? -1) || (a.row ?? -1) - (b.row ?? -1);
    });
  }

  readonly property var filteredWindows: {
    const query = root.filter.trim().toLowerCase();
    if (query.length === 0)
      return root.windows;
    return root.windows.filter(w => `${w.app_id ?? ""} ${w.title ?? ""}`.toLowerCase().includes(query));
  }

  readonly property var selectedWindow: root.filteredWindows[root.selectedIndex] ?? null

  function workspaceLabel(win) {
    const ws = (UmbrielService.workspaces || []).find(x => x.id === win.workspace);
    if (!ws)
      return "";
    return ws.named === true && ws.name ? ws.name : `Workspace ${ws.index}`;
  }

  function iconFor(appId) {
    if (!appId)
      return "";
    return Paths.getAppIcon(appId, DesktopEntries.heuristicLookup(Paths.moddedAppId(appId)));
  }

  // Umbriel's CLI takes the window id as its own word: `umbriel msg window-focus <id>`.
  function runUmbriel(args) {
    Proc.runCommand(`windowSwitcher.${args[0]}.${args[1] ?? ""}`, ["umbriel", ...args], (output, exitCode) => {
      root.log.info("umbriel", args.join(" "), "exit", exitCode, output.trim());
    }, 0);
  }

  function focusWindow(id) {
    console.info("WSDEBUG focusWindow", id);
    if (!id)
      return;
    runUmbriel(["msg", "window-focus", id]);
  }

  function openSwitcher() {
    if (!root.supported) {
      root.log.warn("window switcher needs Umbriel");
      return false;
    }

    const focused = (UmbrielService.windows || []).find(w => w.active === true);
    root.restoreWindowId = focused ? focused.id : "";
    root.filter = "";
    const index = root.windows.findIndex(w => w.id === root.restoreWindowId);
    root.selectedIndex = index >= 0 ? index : 0;
    root.opened = true;
    root.overlayWasActive = false;
    return true;
  }

  // Unmapping the overlay hands the seat back to the compositor, which
  // refocuses on its own. Focus the chosen window a moment later, so the
  // compositor does not undo it.
  Timer {
    id: focusTimer
    interval: 250
    onTriggered: {
      if (root.pendingFocusId) {
        root.focusWindow(root.pendingFocusId);
        root.pendingFocusId = "";
      }
    }
  }

  function closeSwitcher() {
    root.opened = false;
    root.restoreWindowId = "";
  }

  function moveSelection(delta) {
    const count = root.filteredWindows.length;
    if (count === 0)
      return;
    root.selectedIndex = (root.selectedIndex + delta + count) % count;
  }

  function activateSelected() {
    console.info("WSDEBUG activate", root.selectedIndex, JSON.stringify(root.selectedWindow));
    const win = root.selectedWindow;
    root.opened = false;
    root.pendingFocusId = win ? win.id : "";
    root.restoreWindowId = "";
    if (root.pendingFocusId)
      focusTimer.restart();
  }

  IpcHandler {
    target: "window-switcher"

    // Opens the switcher, or moves the selection when it is already open.
    function open(): string {
      if (!root.opened)
        return root.openSwitcher() ? "WINDOW_SWITCHER_OPENED" : "WINDOW_SWITCHER_UNSUPPORTED";
      root.moveSelection(1);
      return "WINDOW_SWITCHER_NEXT";
    }

    function close(): string {
      root.closeSwitcher();
      return "WINDOW_SWITCHER_CLOSED";
    }

    function toggle(): string {
      if (root.opened) {
        root.closeSwitcher();
        return "WINDOW_SWITCHER_CLOSED";
      }
      return root.openSwitcher() ? "WINDOW_SWITCHER_OPENED" : "WINDOW_SWITCHER_UNSUPPORTED";
    }
  }

  PanelWindow {
    id: overlay

    visible: root.opened
    color: "transparent"

    readonly property real cardWidth: Math.min(680, (screen?.width ?? 800) - 64)

    screen: CompositorService.getFocusedScreen()

    WlrLayershell.namespace: "dms:window-switcher"
    WlrLayershell.layer: WlrLayershell.Top
    WlrLayershell.exclusiveZone: -1
    WlrLayershell.keyboardFocus: overlay.visible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    WlrLayershell.margins {
      left: Math.max(0, Math.round(((screen?.width ?? 0) - overlay.cardWidth) / 2))
      top: Math.max(48, Math.round((screen?.height ?? 800) * 0.12))
    }

    anchors {
      left: true
      top: true
    }

    implicitWidth: overlay.cardWidth
    implicitHeight: card.height

    onVisibleChanged: {
      if (visible)
        Qt.callLater(() => cardScope.forceActiveFocus());
    }

    // Clicking another window takes the keyboard away: dismiss instead of lingering.
    Connections {
      target: overlay._backingWindow ?? null

      function onActiveChanged() {
        const win = overlay._backingWindow;
        if (!win)
          return;
        if (win.active) {
          root.overlayWasActive = true;
          return;
        }
        if (root.overlayWasActive && root.opened) {
          root.overlayWasActive = false;
          root.closeSwitcher();
        }
      }
    }

    Rectangle {
      id: card
      width: overlay.cardWidth
      height: cardColumn.implicitHeight + Theme.spacingM * 2
      color: Theme.readableSurface
      radius: Theme.cornerRadius
      border.width: 1
      border.color: Theme.outline

      opacity: root.opened ? 1 : 0

      Behavior on opacity {
        NumberAnimation {
          duration: 120
        }
      }

      Column {
        id: cardColumn
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: Theme.spacingM
        spacing: Theme.spacingS

        Rectangle {
          width: parent.width
          height: 40
          radius: Theme.cornerRadiusM
          color: Theme.surfaceContainerHigh

          Row {
            anchors.fill: parent
            anchors.leftMargin: Theme.spacingS
            anchors.rightMargin: Theme.spacingS
            spacing: Theme.spacingS

            DankIcon {
              name: "search"
              size: 18
              color: Theme.surfaceVariantText
              anchors.verticalCenter: parent.verticalCenter
            }

            StyledText {
              width: parent.width - 30
              anchors.verticalCenter: parent.verticalCenter
              text: root.filter.length > 0 ? root.filter : "Type to filter windows"
              color: root.filter.length > 0 ? Theme.surfaceText : Theme.surfaceVariantText
              font.pixelSize: Theme.fontSizeMedium
              elide: Text.ElideRight
            }
          }
        }

        Repeater {
          model: root.filteredWindows.length > 10 ? root.filteredWindows.slice(0, 10) : root.filteredWindows

          delegate: Rectangle {
            id: row
            required property int index
            required property var modelData

            width: cardColumn.width
            height: 44
            radius: Theme.cornerRadiusM
            color: row.index === root.selectedIndex ? Theme.selectedContainer : "transparent"

            Image {
              id: appIcon
              width: 24
              height: 24
              anchors.left: parent.left
              anchors.leftMargin: Theme.spacingS
              anchors.verticalCenter: parent.verticalCenter
              source: root.iconFor(row.modelData.app_id)
              asynchronous: true
              smooth: true
              fillMode: Image.PreserveAspectFit
            }

            Column {
              anchors.left: appIcon.right
              anchors.leftMargin: Theme.spacingS
              anchors.right: parent.right
              anchors.rightMargin: Theme.spacingS
              anchors.verticalCenter: parent.verticalCenter
              spacing: 0

              StyledText {
                width: parent.width
                text: row.modelData.title || row.modelData.app_id
                color: Theme.surfaceText
                font.pixelSize: Theme.fontSizeMedium
                elide: Text.ElideRight
              }

              StyledText {
                width: parent.width
                text: [row.modelData.app_id, root.workspaceLabel(row.modelData)].filter(x => x).join(" · ")
                color: Theme.surfaceVariantText
                font.pixelSize: Theme.fontSizeSmall
                elide: Text.ElideRight
              }
            }

            MouseArea {
              anchors.fill: parent
              cursorShape: Qt.PointingHandCursor
              onClicked: {
                root.selectedIndex = row.index;
                root.activateSelected();
              }
            }
          }
        }

        StyledText {
          width: parent.width
          visible: root.filteredWindows.length > 10
          text: `…and ${root.filteredWindows.length - 10} more`
          color: Theme.surfaceVariantText
          font.pixelSize: Theme.fontSizeSmall
        }
      }

      FocusScope {
        id: cardScope
        anchors.fill: parent

        Keys.onPressed: event => {
          if (event.key === Qt.Key_Escape) {
            root.closeSwitcher();
            event.accepted = true;
            return;
          }
          if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
            console.info("WSDEBUG enter");
            root.activateSelected();
            event.accepted = true;
            return;
          }
          if (event.key === Qt.Key_Down || event.key === Qt.Key_Tab) {
            root.moveSelection(event.modifiers & Qt.ShiftModifier ? -1 : 1);
            event.accepted = true;
            return;
          }
          if (event.key === Qt.Key_Up) {
            root.moveSelection(-1);
            event.accepted = true;
            return;
          }
          if (event.key === Qt.Key_Backspace) {
            root.filter = root.filter.slice(0, -1);
            root.selectedIndex = 0;
            event.accepted = true;
            return;
          }
          if (event.text && event.text.length === 1 && event.text >= " ") {
            root.filter += event.text;
            root.selectedIndex = 0;
            event.accepted = true;
          }
        }
      }
    }
  }
}
