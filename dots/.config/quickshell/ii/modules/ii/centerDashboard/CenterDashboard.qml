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
    property bool reveal: false

    PanelWindow {
        id: panelWindow
        visible: false

        function hide() {
            GlobalStates.dashboardOpen = false;
        }

        exclusiveZone: 0
        implicitWidth: 720
        implicitHeight: screen.height

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

        function showAnimated() {
            visible = true;
            root.reveal = false;
            openAnimationTimer.restart();
        }

        function hideAnimated() {
            root.reveal = false;
            closeAnimationTimer.restart();
        }

        Timer {
            id: openAnimationTimer
            interval: 32
            repeat: false
            onTriggered: root.reveal = true
        }

        Timer {
            id: closeAnimationTimer
            interval: Appearance.animation.elementMove.duration
            repeat: false
            onTriggered: {
                panelWindow.visible = false;
            }
        }

        Connections {
            target: GlobalFocusGrab
            function onDismissed() {
                panelWindow.hide();
            }
        }

        Connections {
            target: GlobalStates
            function onDashboardOpenChanged() {
                if (GlobalStates.dashboardOpen) {
                    closeAnimationTimer.stop();
                    panelWindow.showAnimated();
                    GlobalFocusGrab.addDismissable(panelWindow);
                } else {
                    GlobalFocusGrab.removeDismissable(panelWindow);
                    panelWindow.hideAnimated();
                }
            }
        }

        Loader {
            id: dashboardContentLoader
            active: true
            anchors.fill: parent
            anchors.margins: Appearance.sizes.hyprlandGapsOut

            focus: GlobalStates.dashboardOpen
            Keys.onPressed: event => {
                if (event.key === Qt.Key_Escape) {
                    panelWindow.hide();
                }
            }

            sourceComponent: CenterDashboardContent {
                property real entryOffset: Math.max(72, Appearance.sizes.barHeight + Appearance.sizes.hyprlandGapsOut * 2)
                y: root.reveal ? 0 : (Config.options.bar.bottom ? entryOffset : -entryOffset)
                opacity: root.reveal ? 1 : 0
                scale: root.reveal ? 1 : 0.985

                Behavior on y {
                    animation: Appearance.animation.elementMoveEnter.numberAnimation.createObject(this)
                }
                Behavior on opacity {
                    animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
                }
                Behavior on scale {
                    animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
                }
            }
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
