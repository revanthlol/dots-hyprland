pragma ComponentBehavior: Bound

import qs.modules.common
import qs.modules.common.widgets
import qs.services
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

// Left pane: user header + live system stats + mini media player.
Rectangle {
    id: root
    color: Appearance.colors.colLayer1
    property string diskUsage: "…"

    Component.onCompleted: diskProc.running = true

    // Poll df every 30 s (stop → small gap → restart to avoid overlapping runs)
    Timer {
        id: diskPollTimer
        interval: 30000
        repeat: true
        running: true
        onTriggered: { diskProc.running = false; diskRestartTimer.restart() }
    }
    Timer {
        id: diskRestartTimer
        interval: 10
        repeat: false
        onTriggered: diskProc.running = true
    }

    Process {
        id: diskProc
        running: false
        command: ["bash", "-c", "df -h / | awk 'NR==2{print $3 \" / \" $2}'"]
        stdout: StdioCollector {
            onStreamFinished: root.diskUsage = text.trim()
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 10

        // ── Header ────────────────────────────────────────────────────────────
        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            CustomIcon {
                Layout.alignment: Qt.AlignVCenter
                width: 36; height: 36
                source: "arch-symbolic"
                colorize: true
                color: Appearance.colors.colPrimary
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 1

                StyledText {
                    Layout.fillWidth: true
                    text: Quickshell.env("USER") || "user"
                    font.pixelSize: Appearance.font.pixelSize.large
                    font.weight: Font.DemiBold
                    color: Appearance.colors.colOnLayer1
                    elide: Text.ElideRight
                }
                StyledText {
                    Layout.fillWidth: true
                    text: "ThinkPad L470 · Arch Linux"
                    color: Appearance.colors.colSubtext
                    font.pixelSize: Appearance.font.pixelSize.smaller
                    elide: Text.ElideRight
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 1
            color: Appearance.colors.colLayer0Border
        }

        // ── Live stats ────────────────────────────────────────────────────────
        StatRow {
            icon: "planner_review"
            label: "CPU"
            value: `${Math.round(ResourceUsage.cpuUsage * 100)}%`
            progress: ResourceUsage.cpuUsage
            warning: ResourceUsage.cpuUsage >= 0.85
        }

        StatRow {
            icon: "memory"
            label: "RAM"
            value: `${Math.round(ResourceUsage.memoryUsedPercentage * 100)}%`
            progress: ResourceUsage.memoryUsedPercentage
            warning: ResourceUsage.memoryUsedPercentage >= 0.85
        }

        StatRow {
            icon: "storage"
            label: "Disk"
            value: root.diskUsage
            progress: -1
            warning: false
        }

        StatRow {
            icon: Battery.isCharging ? "battery_charging_full" : "battery_5_bar"
            label: "Bat"
            value: `${Math.round(Battery.percentage * 100)}%${Battery.isPluggedIn ? " ⚡" : ""}`
            progress: Battery.percentage
            warning: !Battery.isCharging && Battery.percentage <= 0.15
        }

        StatRow {
            icon: Network.materialSymbol
            label: "WiFi"
            value: Network.wifiStatus !== "disabled"
                   ? (Network.networkName || "Connected") : "Off"
            progress: -1
            warning: false
        }

        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 1
            color: Appearance.colors.colLayer0Border
        }

        // ── Now Playing ───────────────────────────────────────────────────────
        StyledText {
            text: Translation.tr("Now Playing")
            font.weight: Font.DemiBold
            font.pixelSize: Appearance.font.pixelSize.small
            color: Appearance.colors.colSubtext
        }

        MiniPlayer {
            Layout.fillWidth: true
        }

        Item { Layout.fillHeight: true }
    }
}
