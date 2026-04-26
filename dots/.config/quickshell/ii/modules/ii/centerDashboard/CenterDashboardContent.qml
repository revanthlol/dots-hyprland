import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Bluetooth
import Quickshell.Hyprland
import Quickshell.Services.Mpris
import qs.modules.ii.centerDashboard.calendar
import qs.modules.common.functions


import qs.modules.ii.centerDashboard.quickToggles
import qs.modules.ii.centerDashboard.quickToggles.classicStyle

import qs.modules.ii.centerDashboard.bluetoothDevices
import qs.modules.ii.centerDashboard.nightLight
import qs.modules.ii.centerDashboard.volumeMixer
import qs.modules.ii.centerDashboard.wifiNetworks

Item {
    id: root
    property int sidebarWidth: Appearance.sizes.sidebarWidth
    property int sidebarPadding: 10
    property string settingsQmlPath: Quickshell.shellPath("settings.qml")
    property bool showAudioOutputDialog: false
    property bool showAudioInputDialog: false
    property bool showBluetoothDialog: false
    property bool showNightLightDialog: false
    property bool showWifiDialog: false
    property bool editMode: false

    Connections {
        target: GlobalStates
        function onDashboardOpenChanged() {
            if (!GlobalStates.dashboardOpen) {
                root.showWifiDialog = false;
                root.showBluetoothDialog = false;
                root.showAudioOutputDialog = false;
                root.showAudioInputDialog = false;
            }
        }
    }

    implicitHeight: dashboardBackground.implicitHeight
    implicitWidth: dashboardBackground.implicitWidth

    StyledRectangularShadow {
        target: dashboardBackground
    }
    Rectangle {
        id: dashboardBackground

        anchors.fill: parent
        implicitHeight: parent.height - Appearance.sizes.hyprlandGapsOut * 2
        implicitWidth: sidebarWidth - Appearance.sizes.hyprlandGapsOut * 2
        color: Appearance.colors.colLayer0
        border.width: 1
        border.color: Appearance.colors.colLayer0Border
        radius: Appearance.rounding.screenRounding - Appearance.sizes.hyprlandGapsOut + 1

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: sidebarPadding
            spacing: sidebarPadding

            SystemButtonRow {
                Layout.fillHeight: false
                Layout.fillWidth: true
                // Layout.margins: 10
                Layout.topMargin: 5
                Layout.bottomMargin: 0
            }

            // Big clock
            Item {
                Layout.fillWidth: true
                Layout.fillHeight: false
                implicitHeight: clockColumn.implicitHeight + 16
                Column {
                    id: clockColumn
                    anchors.centerIn: parent
                    spacing: 2
                    StyledText {
                        anchors.horizontalCenter: parent.horizontalCenter
                        font.pixelSize: 48
                        font.weight: Font.Light
                        color: Appearance.colors.colOnLayer0
                        text: DateTime.timeWithSeconds
                    }
                    StyledText {
                        anchors.horizontalCenter: parent.horizontalCenter
                        font.pixelSize: Appearance.font.pixelSize.normal
                        color: Appearance.colors.colSubtext
                        text: DateTime.longDate
                    }
                }
            }

            Loader {
                id: slidersLoader
                Layout.fillWidth: true
                visible: active
                active: {
                    const configQuickSliders = Config.options.sidebar.quickSliders
                    if (!configQuickSliders.enable) return false
                    if (!configQuickSliders.showMic && !configQuickSliders.showVolume && !configQuickSliders.showBrightness) return false;
                    return true;
                }
                sourceComponent: QuickSliders {}
            }

            LoaderedQuickPanelImplementation {
                styleName: "classic"
                sourceComponent: ClassicQuickPanel {}
            }

            LoaderedQuickPanelImplementation {
                styleName: "android"
                sourceComponent: AndroidQuickPanel {
                    editMode: root.editMode
                }
            }

            // Notifications
            CenterWidgetGroup {
                Layout.alignment: Qt.AlignHCenter
                Layout.fillHeight: true
                Layout.fillWidth: true
            }

            // Shared accordion header
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: accordionRow.implicitHeight + 12
                color: Appearance.colors.colLayer1
                radius: Appearance.rounding.normal

                property bool collapsed: Persistent.states.sidebar.bottomGroup.collapsed

                RowLayout {
                    id: accordionRow
                    anchors.fill: parent
                    anchors.margins: 6

                    CalendarHeaderButton {
                        forceCircle: true
                        downAction: () => {
                            Persistent.states.sidebar.bottomGroup.collapsed = !Persistent.states.sidebar.bottomGroup.collapsed
                        }
                        contentItem: MaterialSymbol {
                            text: Persistent.states.sidebar.bottomGroup.collapsed ? "keyboard_arrow_down" : "keyboard_arrow_up"
                            iconSize: Appearance.font.pixelSize.larger
                            horizontalAlignment: Text.AlignHCenter
                            color: Appearance.colors.colOnLayer1
                        }
                    }
                    StyledText {
                        Layout.fillWidth: true
                        Layout.leftMargin: 8
                        text: Persistent.states.sidebar.bottomGroup.collapsed ? DateTime.collapsedCalendarFormat : Translation.tr("Player & Calendar")
                        font.pixelSize: Appearance.font.pixelSize.normal
                        color: Appearance.colors.colOnLayer1
                    }
                }
            }

            // Player + Calendar row (collapsible)
            Item {
                Layout.fillWidth: true
                implicitHeight: Persistent.states.sidebar.bottomGroup.collapsed ? 0 : bottomRow.implicitHeight
                clip: true
                visible: implicitHeight > 0

                Behavior on implicitHeight {
                    NumberAnimation {
                        duration: Appearance.animation.elementMove.duration
                        easing.type: Appearance.animation.elementMove.type
                        easing.bezierCurve: Appearance.animation.elementMove.bezierCurve
                    }
                }

                RowLayout {
                    id: bottomRow
                    anchors.left: parent.left
                    anchors.right: parent.right
                    spacing: sidebarPadding
                    implicitHeight: Math.max(playerCard.implicitHeight, calendarCard.implicitHeight)

                    // Player — vertical iPhone style
                    Rectangle {
                        id: playerCard
                        Layout.fillWidth: true
                        Layout.preferredWidth: 1
                        implicitHeight: 350
                        radius: Appearance.rounding.normal
                        color: Appearance.colors.colLayer1
                        clip: true

                        Timer {
                            running: MprisController.activePlayer?.isPlaying ?? false
                            interval: 1000
                            repeat: true
                            onTriggered: {
                                if (MprisController.activePlayer)
                                    MprisController.activePlayer.positionChanged()
                            }
                        }



                        ColumnLayout {
                            anchors.fill: parent
                            spacing: 0
                            visible: MprisController.activePlayer !== null

                            // Cover art — top half
                            Rectangle {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 160
                                color: Appearance.colors.colLayer2
                                clip: true

                                Item {
                                    anchors.fill: parent
                                    Image {
                                        id: coverArtImage
                                        anchors.fill: parent
                                        source: MprisController.activePlayer?.trackArtUrl ?? ""
                                        fillMode: Image.PreserveAspectCrop
                                        cache: true
                                        asynchronous: true
                                        Behavior on source {
                                            enabled: false
                                        }
                                        opacity: status === Image.Ready ? 1 : 0
                                        Behavior on opacity {
                                            NumberAnimation { duration: 200 }
                                        }
                                    }
                                }
                            }

                            // Track info + controls — bottom half
                            ColumnLayout {
                                Layout.fillWidth: true
                                Layout.margins: 10
                                spacing: 6

                                StyledText {
                                    Layout.fillWidth: true
                                    font.pixelSize: Appearance.font.pixelSize.normal
                                    font.weight: Font.Medium
                                    color: Appearance.colors.colOnLayer0
                                    elide: Text.ElideRight
                                    text: MprisController.activePlayer?.trackTitle ?? "Untitled"
                                }
                                StyledText {
                                    Layout.fillWidth: true
                                    font.pixelSize: Appearance.font.pixelSize.smaller
                                    color: Appearance.colors.colSubtext
                                    elide: Text.ElideRight
                                    text: MprisController.activePlayer?.trackArtist ?? ""
                                }

                                // Progress bar
                                Item {
                                    Layout.fillWidth: true
                                    implicitHeight: 20

                                    Loader {
                                        anchors.fill: parent
                                        active: MprisController.activePlayer?.canSeek ?? false
                                        sourceComponent: StyledSlider {
                                            configuration: StyledSlider.Configuration.Wavy
                                            highlightColor: Appearance.colors.colPrimary
                                            trackColor: Appearance.colors.colSecondaryContainer
                                            handleColor: Appearance.colors.colPrimary
                                            value: (MprisController.activePlayer?.position ?? 0) / (MprisController.activePlayer?.length ?? 1)
                                            onMoved: {
                                                if (MprisController.activePlayer)
                                                    MprisController.activePlayer.position = value * MprisController.activePlayer.length
                                            }
                                        }
                                    }

                                    Loader {
                                        anchors.verticalCenter: parent.verticalCenter
                                        anchors.left: parent.left
                                        anchors.right: parent.right
                                        active: !(MprisController.activePlayer?.canSeek ?? false)
                                        sourceComponent: StyledProgressBar {
                                            wavy: MprisController.activePlayer?.isPlaying ?? false
                                            highlightColor: Appearance.colors.colPrimary
                                            trackColor: Appearance.colors.colSecondaryContainer
                                            value: (MprisController.activePlayer?.position ?? 0) / (MprisController.activePlayer?.length ?? 1)
                                        }
                                    }
                                }

                                // Position text
                                StyledText {
                                    Layout.fillWidth: true
                                    font.pixelSize: Appearance.font.pixelSize.smaller
                                    color: Appearance.colors.colSubtext
                                    text: `${StringUtils.friendlyTimeForSeconds(MprisController.activePlayer?.position ?? 0)} / ${StringUtils.friendlyTimeForSeconds(MprisController.activePlayer?.length ?? 0)}`
                                }

                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 8
                                    RippleButton {
                                        implicitWidth: 32; implicitHeight: 32
                                        buttonRadius: 16
                                        colBackground: Appearance.colors.colSecondaryContainer
                                        colBackgroundHover: Appearance.colors.colSecondaryContainerHover
                                        colRipple: Appearance.colors.colSecondaryContainerActive
                                        downAction: () => MprisController.activePlayer?.previous()
                                        contentItem: MaterialSymbol {
                                            text: "skip_previous"
                                            iconSize: Appearance.font.pixelSize.larger
                                            horizontalAlignment: Text.AlignHCenter
                                            color: Appearance.colors.colOnLayer0
                                        }
                                    }
                                    RippleButton {
                                        Layout.fillWidth: true
                                        implicitHeight: 32
                                        buttonRadius: Appearance.rounding.normal
                                        colBackground: Appearance.colors.colPrimary
                                        colBackgroundHover: Appearance.colors.colPrimaryHover
                                        colRipple: Appearance.colors.colPrimaryActive
                                        downAction: () => MprisController.activePlayer?.togglePlaying()
                                        contentItem: MaterialSymbol {
                                            text: MprisController.activePlayer?.isPlaying ? "pause" : "play_arrow"
                                            iconSize: Appearance.font.pixelSize.larger
                                            horizontalAlignment: Text.AlignHCenter
                                            color: Appearance.colors.colOnPrimary
                                        }
                                    }
                                    RippleButton {
                                        implicitWidth: 32; implicitHeight: 32
                                        buttonRadius: 16
                                        colBackground: Appearance.colors.colSecondaryContainer
                                        colBackgroundHover: Appearance.colors.colSecondaryContainerHover
                                        colRipple: Appearance.colors.colSecondaryContainerActive
                                        downAction: () => MprisController.activePlayer?.next()
                                        contentItem: MaterialSymbol {
                                            text: "skip_next"
                                            iconSize: Appearance.font.pixelSize.larger
                                            horizontalAlignment: Text.AlignHCenter
                                            color: Appearance.colors.colOnLayer0
                                        }
                                    }
                                }
                            }
                        }

                        // No player placeholder
                        StyledText {
                            anchors.centerIn: parent
                            visible: MprisController.activePlayer === null
                            text: Translation.tr("No active player")
                            color: Appearance.colors.colSubtext
                            font.pixelSize: Appearance.font.pixelSize.small
                        }
                    }

                    // Calendar
                    Rectangle {
                        id: calendarCard
                        Layout.fillWidth: true
                        Layout.preferredWidth: 1
                        implicitHeight: 350
                        radius: Appearance.rounding.normal
                        color: Appearance.colors.colLayer1
                        clip: true

                        CalendarWidget {
                            anchors.fill: parent
                            anchors.margins: 8
                        }
                    }
                }
            }
        }
    }

    ToggleDialog {
        shownPropertyString: "showAudioOutputDialog"
        dialog: VolumeDialog {
            isSink: true
        }
    }

    ToggleDialog {
        shownPropertyString: "showAudioInputDialog"
        dialog: VolumeDialog {
            isSink: false
        }
    }

    ToggleDialog {
        shownPropertyString: "showBluetoothDialog"
        dialog: BluetoothDialog {}
        onShownChanged: {
            if (!shown) {
                Bluetooth.defaultAdapter.discovering = false;
            } else {
                Bluetooth.defaultAdapter.enabled = true;
                Bluetooth.defaultAdapter.discovering = true;
            }
        }
    }

    ToggleDialog {
        shownPropertyString: "showNightLightDialog"
        dialog: NightLightDialog {}
    }

    ToggleDialog {
        shownPropertyString: "showWifiDialog"
        dialog: WifiDialog {}
        onShownChanged: {
            if (!shown) return;
            Network.enableWifi();
            Network.rescanWifi();
        }
    }

    component ToggleDialog: Loader {
        id: toggleDialogLoader
        required property string shownPropertyString
        property alias dialog: toggleDialogLoader.sourceComponent
        readonly property bool shown: root[shownPropertyString]
        anchors.fill: parent

        onShownChanged: if (shown) toggleDialogLoader.active = true;
        active: shown
        onActiveChanged: {
            if (active) {
                item.show = true;
                item.forceActiveFocus();
            }
        }
        Connections {
            target: toggleDialogLoader.item
            function onDismiss() {
                toggleDialogLoader.item.show = false
                root[toggleDialogLoader.shownPropertyString] = false;
            }
            function onVisibleChanged() {
                if (!toggleDialogLoader.item.visible && !root[toggleDialogLoader.shownPropertyString]) toggleDialogLoader.active = false;
            }
        }
    }

    component LoaderedQuickPanelImplementation: Loader {
        id: quickPanelImplLoader
        required property string styleName
        Layout.alignment: item?.Layout.alignment ?? Qt.AlignHCenter
        Layout.fillWidth: item?.Layout.fillWidth ?? false
        visible: active
        active: Config.options.sidebar.quickToggles.style === styleName
        Connections {
            target: quickPanelImplLoader.item
            function onOpenAudioOutputDialog() {
                root.showAudioOutputDialog = true;
            }
            function onOpenAudioInputDialog() {
                root.showAudioInputDialog = true;
            }
            function onOpenBluetoothDialog() {
                root.showBluetoothDialog = true;
            }
            function onOpenNightLightDialog() {
                root.showNightLightDialog = true;
            }
            function onOpenWifiDialog() {
                root.showWifiDialog = true;
            }
        }
    }

    component SystemButtonRow: Item {
        implicitHeight: Math.max(uptimeContainer.implicitHeight, systemButtonsRow.implicitHeight)

        Rectangle {
            id: uptimeContainer
            anchors {
                top: parent.top
                bottom: parent.bottom
                left: parent.left
            }
            color: Appearance.colors.colLayer1
            radius: height / 2
            implicitWidth: uptimeRow.implicitWidth + 24
            implicitHeight: uptimeRow.implicitHeight + 8
            
            Row {
                id: uptimeRow
                anchors.centerIn: parent
                spacing: 8
                CustomIcon {
                    id: distroIcon
                    anchors.verticalCenter: parent.verticalCenter
                    width: 25
                    height: 25
                    source: SystemInfo.distroIcon
                    colorize: true
                    color: Appearance.colors.colOnLayer0
                }
                StyledText {
                    anchors.verticalCenter: parent.verticalCenter
                    font.pixelSize: Appearance.font.pixelSize.normal
                    color: Appearance.colors.colOnLayer0
                    text: Translation.tr("Up %1").arg(DateTime.uptime)
                    textFormat: Text.MarkdownText
                }
            }
        }

        ButtonGroup {
            id: systemButtonsRow
            anchors {
                top: parent.top
                bottom: parent.bottom
                right: parent.right
            }
            color: Appearance.colors.colLayer1
            padding: 4

            QuickToggleButton {
                toggled: root.editMode
                visible: Config.options.sidebar.quickToggles.style === "android"
                buttonIcon: "edit"
                onClicked: root.editMode = !root.editMode
                StyledToolTip {
                    text: Translation.tr("Edit quick toggles") + (root.editMode ? Translation.tr("\nLMB to enable/disable\nRMB to toggle size\nScroll to swap position") : "")
                }
            }
            QuickToggleButton {
                toggled: false
                buttonIcon: "restart_alt"
                onClicked: {
                    Hyprland.dispatch("reload");
                    Quickshell.reload(true);
                }
                StyledToolTip {
                    text: Translation.tr("Reload Hyprland & Quickshell")
                }
            }
            QuickToggleButton {
                toggled: false
                buttonIcon: "settings"
                onClicked: {
                    GlobalStates.dashboardOpen = false;
                    Quickshell.execDetached(["qs", "-p", root.settingsQmlPath]);
                }
                StyledToolTip {
                    text: Translation.tr("Settings")
                }
            }
            QuickToggleButton {
                toggled: false
                buttonIcon: "power_settings_new"
                onClicked: {
                    GlobalStates.sessionOpen = true;
                }
                StyledToolTip {
                    text: Translation.tr("Session")
                }
            }
        }
    }
}
