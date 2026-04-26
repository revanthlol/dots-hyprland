import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.UPower
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions

Item { // Bar content region
    id: root
    implicitWidth: mainRow.implicitWidth

    property var screen: root.QsWindow.window?.screen
    property var brightnessMonitor: Brightness.getMonitorForScreen(screen)
    property real useShortenedForm: (Appearance.sizes.barHellaShortenScreenWidthThreshold >= screen?.width) ? 2 : (Appearance.sizes.barShortenScreenWidthThreshold >= screen?.width) ? 1 : 0
    readonly property int centerSideModuleWidth: (useShortenedForm == 2) ? Appearance.sizes.barCenterSideModuleWidthHellaShortened : (useShortenedForm == 1) ? Appearance.sizes.barCenterSideModuleWidthShortened : Appearance.sizes.barCenterSideModuleWidth

    component VerticalBarSeparator: Rectangle {
        Layout.topMargin: Appearance.sizes.baseBarHeight / 3
        Layout.bottomMargin: Appearance.sizes.baseBarHeight / 3
        Layout.fillHeight: true
        implicitWidth: 1
        color: Appearance.colors.colOutlineVariant
    }

    // Background shadow
    Loader {
        active: Config.options.bar.showBackground && Config.options.bar.cornerStyle === 1 && Config.options.bar.floatStyleShadow
        anchors.fill: barBackground
        sourceComponent: StyledRectangularShadow {
            anchors.fill: undefined // The loader's anchors act on this, and this should not have any anchor
            target: barBackground
        }
    }
    // Background
    Rectangle {
        id: barBackground
        anchors {
            fill: parent
            margins: Config.options.bar.cornerStyle === 1 ? (Appearance.sizes.hyprlandGapsOut) : 0 // idk why but +1 is needed
        }
        color: Config.options.bar.showBackground ? Appearance.colors.colLayer0 : "transparent"
        radius: Config.options.bar.cornerStyle === 1 ? Appearance.rounding.windowRounding : 0
        border.width: Config.options.bar.cornerStyle === 1 ? 1 : 0
        border.color: Appearance.colors.colLayer0Border
    }

    RowLayout {
        id: mainRow
        anchors.centerIn: parent
        spacing: 8

        Item { Layout.preferredWidth: 4 } // Padding: 4 (width) + 8 (spacing) = 12px

        // Left
        RowLayout {
            spacing: 6
            Layout.alignment: Qt.AlignVCenter
            LeftSidebarButton {
                Layout.alignment: Qt.AlignVCenter
                colBackground: "transparent"
            }
            Resources {
                Layout.alignment: Qt.AlignVCenter
            }
        }

        // Center - workspaces
        BarGroup {
            Layout.alignment: Qt.AlignVCenter
            Layout.fillWidth: false
            padding: workspacesWidget.widgetPadding
            Workspaces {
                id: workspacesWidget
                Layout.fillHeight: true
                MouseArea {
                    anchors.fill: parent
                    acceptedButtons: Qt.RightButton
                    onPressed: event => {
                        if (event.button === Qt.RightButton)
                            GlobalStates.overviewOpen = !GlobalStates.overviewOpen;
                    }
                }
            }
        }

        // Right
        RowLayout {
            spacing: 10
            Layout.alignment: Qt.AlignVCenter
            SysTray {
                Layout.fillHeight: true
                invertSide: Config?.options.bar.bottom
            }
            ClockWidget {
                showDate: Config.options.bar.verbose
                Layout.alignment: Qt.AlignVCenter
                Layout.leftMargin: 4
            }
            BatteryIndicator {
                visible: Battery.available
                Layout.alignment: Qt.AlignVCenter
                Layout.leftMargin: 4
            }
            RippleButton {
                id: rightSidebarButton
                Layout.alignment: Qt.AlignVCenter
                implicitWidth: indicatorsRowLayout.implicitWidth + 16
                implicitHeight: indicatorsRowLayout.implicitHeight + 8
                buttonRadius: Appearance.rounding.full
                colBackground: "transparent"
                colBackgroundHover: Appearance.colors.colLayer1Hover
                colRipple: Appearance.colors.colLayer1Active
                colBackgroundToggled: Appearance.colors.colSecondaryContainer
                colBackgroundToggledHover: Appearance.colors.colSecondaryContainerHover
                colRippleToggled: Appearance.colors.colSecondaryContainerActive
                toggled: GlobalStates.dashboardOpen
                property color colText: toggled ? Appearance.m3colors.m3onSecondaryContainer : Appearance.colors.colOnLayer0
                Behavior on colText {
                    animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
                }
                onPressed: GlobalStates.dashboardOpen = !GlobalStates.dashboardOpen
                RowLayout {
                    id: indicatorsRowLayout
                    anchors.centerIn: parent
                    spacing: 8
                    MaterialSymbol {
                        text: Network.materialSymbol
                        iconSize: Appearance.font.pixelSize.larger
                        color: rightSidebarButton.colText
                    }
                    MaterialSymbol {
                        visible: BluetoothStatus.available
                        text: BluetoothStatus.connected ? "bluetooth_connected" : BluetoothStatus.enabled ? "bluetooth" : "bluetooth_disabled"
                        iconSize: Appearance.font.pixelSize.larger
                        color: rightSidebarButton.colText
                    }
                    NotificationUnreadCount {
                        id: notificationUnreadCount
                        visible: Notifications.silent || Notifications.unread > 0
                    }
                }
            }
        }

        Item { Layout.preferredWidth: 4 } // Padding: 4 (width) + 8 (spacing) = 12px
    }
}
