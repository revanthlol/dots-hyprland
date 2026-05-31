pragma ComponentBehavior: Bound

import qs
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets
import qs.services
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Widgets

Scope {
    id: root

    // ── State ─────────────────────────────────────────────────────────────────
    property bool   reveal: false
    property string query: ""
    property int    selectedIndex: 0
    property int    sortMode: 0      // 0 = name, 1 = id
    property bool   gridView: false
    readonly property int maxResults: 200

    // Spread AppSearch.list into a plain JS array so:
    //  • Array sort methods work reliably
    //  • The binding re-evaluates whenever AppSearch.list changes
    //    (handles DesktopEntries async-load race on startup)
    readonly property var sortedApps: {
        const apps = [...AppSearch.list];
        if (sortMode === 1)
            return apps.sort((a, b) => (a?.id ?? "").localeCompare(b?.id ?? ""));
        return apps.sort((a, b) => (a?.name ?? "").localeCompare(b?.name ?? ""));
    }

    readonly property var visibleApps: {
        const q = query.trim();
        if (q.length === 0) return sortedApps.slice(0, maxResults);
        const results = AppSearch.fuzzyQuery(q);
        return (Array.isArray(results) ? results : []).slice(0, maxResults);
    }

    // ── Actions ───────────────────────────────────────────────────────────────
    function close() {
        GlobalStates.quickLauncherOpen = false;
    }

    function clampSelection() {
        selectedIndex = Math.max(0, Math.min(selectedIndex, visibleApps.length - 1));
    }

    function executeApp(entry) {
        if (!entry) return;
        entry.execute();
        root.close();
    }

    // ── Panel window ──────────────────────────────────────────────────────────
    PanelWindow {
        id: panelWindow
        visible: false
        exclusiveZone: 0
        implicitWidth:  Math.min(1000, Math.max(800,  screen.width  * 0.64))
        implicitHeight: Math.min(640,  Math.max(480,  screen.height * 0.60))
        color: "transparent"

        WlrLayershell.namespace: "quickshell:quickLauncher"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: GlobalStates.quickLauncherOpen
            ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

        anchors { top: true; bottom: true; left: true; right: true }
        margins {
            top:    Math.max(Appearance.sizes.barHeight + Appearance.sizes.hyprlandGapsOut,
                            (screen.height - implicitHeight) / 2)
            bottom: Math.max(Appearance.sizes.barHeight + Appearance.sizes.hyprlandGapsOut,
                            (screen.height - implicitHeight) / 2)
            left:   (screen.width - implicitWidth) / 2
            right:  (screen.width - implicitWidth) / 2
        }

        function showAnimated() {
            visible = true;
            root.reveal = false;
            root.query = "";
            root.selectedIndex = 0;
            focusTimer.restart();
            openAnimationTimer.restart();
        }

        function hideAnimated() {
            root.reveal = false;
            closeAnimationTimer.restart();
        }

        Timer {
            id: openAnimationTimer
            interval: 16; repeat: false
            onTriggered: root.reveal = true
        }
        Timer {
            id: closeAnimationTimer
            interval: 150; repeat: false
            onTriggered: panelWindow.visible = false
        }
        Timer {
            id: focusTimer
            interval: 10; repeat: false
            onTriggered: appListPane.focusSearch()
        }

        Connections {
            target: GlobalFocusGrab
            function onDismissed() { root.close(); }
        }

        Connections {
            target: GlobalStates
            function onQuickLauncherOpenChanged() {
                if (GlobalStates.quickLauncherOpen) {
                    closeAnimationTimer.stop();
                    panelWindow.showAnimated();
                    GlobalFocusGrab.addDismissable(panelWindow);
                } else {
                    GlobalFocusGrab.removeDismissable(panelWindow);
                    panelWindow.hideAnimated();
                }
            }
        }

        StyledRectangularShadow { target: launcherFrame }

        Rectangle {
            id: launcherFrame
            anchors.fill: parent
            color: Appearance.colors.colLayer0
            border { width: 1; color: Appearance.colors.colLayer0Border }
            radius: Appearance.rounding.large
            clip: true

            opacity: root.reveal ? 1 : 0
            y:       root.reveal ? 0 : 25 // Snappy clean slide up (doesn't clip)
            scale:   root.reveal ? 1 : 0.98

            Behavior on y {
                NumberAnimation {
                    duration: 100
                    easing.type: Easing.OutQuad
                }
            }
            Behavior on opacity {
                NumberAnimation {
                    duration: 80
                    easing.type: Easing.OutQuad
                }
            }
            Behavior on scale {
                NumberAnimation {
                    duration: 100
                    easing.type: Easing.OutQuad
                }
            }

            RowLayout {
                anchors.fill: parent
                spacing: 0

                // Left pane ─────────────────────────────────────────────────────
                SystemInfoPane {
                    Layout.fillHeight: true
                    Layout.preferredWidth: 340
                }

                Rectangle {
                    Layout.fillHeight: true
                    implicitWidth: 1
                    color: Appearance.colors.colLayer0Border
                }

                // Right pane ────────────────────────────────────────────────────
                AppListPane {
                    id: appListPane
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    visibleApps:   root.visibleApps
                    query:         root.query
                    selectedIndex: root.selectedIndex
                    gridView:      root.gridView
                    sortMode:      root.sortMode

                    onQueryModified:         (q) => root.query = q
                    onSelectedIndexModified: (i) => root.selectedIndex = i
                    onGridViewModified:      (g) => { root.gridView = g; root.clampSelection(); }
                    onSortModeModified:      (m) => { root.sortMode = m; root.selectedIndex = 0; }
                    onAppExecuted:          (e) => root.executeApp(e)
                    onCloseRequested:       root.close()
                }
            }
        }
    }

    // ── IPC ───────────────────────────────────────────────────────────────────
    IpcHandler {
        target: "quickLauncher"
        function toggle(): void { GlobalStates.quickLauncherOpen = !GlobalStates.quickLauncherOpen; }
        function open():   void { GlobalStates.quickLauncherOpen = true; }
        function close():  void { GlobalStates.quickLauncherOpen = false; }
    }
}
