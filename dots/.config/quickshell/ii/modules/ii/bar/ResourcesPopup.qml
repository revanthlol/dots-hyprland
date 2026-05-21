import qs.modules.common
import qs.modules.common.widgets
import qs.services
import QtQuick
import QtQuick.Layouts

StyledPopup {
    id: root

    // Helper function to format KB to GB
    function formatKB(kb) {
        return (kb / (1024 * 1024)).toFixed(1) + " GB";
    }

    Row {
        anchors.centerIn: parent
        spacing: 12

        Column {
            anchors.top: parent.top
            spacing: 8

            StyledPopupHeaderRow {
                icon: "memory"
                label: "RAM"
            }
            Column {
                spacing: 4
                StyledPopupValueRow {
                    icon: "clock_loader_60"
                    label: Translation.tr("Used:")
                    value: root.formatKB(ResourceUsage.memoryUsed)
                }
                StyledPopupValueRow {
                    icon: "check_circle"
                    label: Translation.tr("Free:")
                    value: root.formatKB(ResourceUsage.memoryFree)
                }
                StyledPopupValueRow {
                    icon: "empty_dashboard"
                    label: Translation.tr("Total:")
                    value: root.formatKB(ResourceUsage.memoryTotal)
                }
            }
        }

        Column {
            visible: ResourceUsage.swapTotal > 0
            anchors.top: parent.top
            spacing: 8

            StyledPopupHeaderRow {
                icon: "swap_horiz"
                label: "Swap"
            }
            Column {
                spacing: 4
                StyledPopupValueRow {
                    icon: "clock_loader_60"
                    label: Translation.tr("Used:")
                    value: root.formatKB(ResourceUsage.swapUsed)
                }
                StyledPopupValueRow {
                    icon: "check_circle"
                    label: Translation.tr("Free:")
                    value: root.formatKB(ResourceUsage.swapFree)
                }
                StyledPopupValueRow {
                    icon: "empty_dashboard"
                    label: Translation.tr("Total:")
                    value: root.formatKB(ResourceUsage.swapTotal)
                }
            }
        }

        Column {
            anchors.top: parent.top
            spacing: 8

            StyledPopupHeaderRow {
                icon: "planner_review"
                label: "CPU"
            }
            Column {
                spacing: 4
                StyledPopupValueRow {
                    icon: "bolt"
                    label: Translation.tr("Usage:")
                    value: ResourceUsage.cpuUsageString
                }
                StyledPopupValueRow {
                    icon: "developer_board"
                    label: Translation.tr("Cores:")
                    value: `${ResourceUsage.cpuCores || "--"}C / ${ResourceUsage.cpuThreads || "--"}T`
                }
                StyledPopupValueRow {
                    icon: "monitoring"
                    label: Translation.tr("Load 1m:")
                    value: ResourceUsage.loadAverageOneMinuteString
                }
            }
        }

        Column {
            anchors.top: parent.top
            spacing: 8

            StyledPopupHeaderRow {
                icon: Network.materialSymbol
                label: Network.ethernet ? "LAN" : "Wi-Fi"
            }
            Column {
                spacing: 4
                StyledPopupValueRow {
                    icon: "download"
                    label: Translation.tr("Down:")
                    value: Network.formatRate(Network.downloadBytesPerSecond)
                }
                StyledPopupValueRow {
                    icon: "upload"
                    label: Translation.tr("Up:")
                    value: Network.formatRate(Network.uploadBytesPerSecond)
                }
                StyledPopupValueRow {
                    icon: "router"
                    label: Translation.tr("SSID:")
                    value: Network.networkName || Translation.tr("Disconnected")
                }
                StyledPopupValueRow {
                    visible: Network.wifi
                    icon: "network_wifi"
                    label: Translation.tr("Signal:")
                    value: `${Network.networkStrength || 0}%`
                }
            }
        }
    }
}
