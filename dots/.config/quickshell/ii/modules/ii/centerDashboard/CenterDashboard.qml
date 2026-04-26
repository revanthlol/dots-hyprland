import qs
import qs.services
import qs.modules.common
import QtQuick
import Quickshell.Io
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland

Scope {
    id: root

    PanelWindow {
        id: panelWindow
        visible: GlobalStates.dashboardOpen

        function hide() {
            GlobalStates.dashboardOpen = false;
        }

        exclusiveZone: 0
        implicitWidth: 460
        implicitHeight: 880

        WlrLayershell.namespace: "quickshell:centerDashboard"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: GlobalStates.dashboardOpen ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
        color: "transparent"

        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }
        margins {
            top: (screen.height - implicitHeight) / 2
            bottom: (screen.height - implicitHeight) / 2
            left: (screen.width - implicitWidth) / 2
            right: (screen.width - implicitWidth) / 2
        }

        onVisibleChanged: {
            if (visible) {
                GlobalFocusGrab.addDismissable(panelWindow);
            } else {
                GlobalFocusGrab.removeDismissable(panelWindow);
            }
        }
        Connections {
            target: GlobalFocusGrab
            function onDismissed() {
                panelWindow.hide();
            }
        }

        Loader {
            id: dashboardContentLoader
            active: GlobalStates.dashboardOpen || false
            anchors.fill: parent
            anchors.margins: Appearance.sizes.hyprlandGapsOut

            focus: GlobalStates.dashboardOpen
            Keys.onPressed: event => {
                if (event.key === Qt.Key_Escape) {
                    panelWindow.hide();
                }
            }

            sourceComponent: CenterDashboardContent {}
        }
    }

    IpcHandler {
        target: "dashboard"

        function toggle(): void {
            GlobalStates.dashboardOpen = !GlobalStates.dashboardOpen;
        }

        function close(): void {
            GlobalStates.dashboardOpen = false;
        }

        function open(): void {
            GlobalStates.dashboardOpen = true;
        }
    }

    GlobalShortcut {
        name: "dashboardToggle"
        description: "Toggles dashboard on press"

        onPressed: {
            GlobalStates.dashboardOpen = !GlobalStates.dashboardOpen;
        }
    }
    GlobalShortcut {
        name: "dashboardOpen"
        description: "Opens dashboard on press"

        onPressed: {
            GlobalStates.dashboardOpen = true;
        }
    }
    GlobalShortcut {
        name: "dashboardClose"
        description: "Closes dashboard on press"

        onPressed: {
            GlobalStates.dashboardOpen = false;
        }
    }
}
