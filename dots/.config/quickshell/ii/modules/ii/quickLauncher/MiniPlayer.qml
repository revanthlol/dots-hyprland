pragma ComponentBehavior: Bound

import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets
import qs.services
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

// Vertical mini-player: album art → title → artist → time → wavy progress → controls.
// Self-contained: reads MprisController.activePlayer directly.
ColumnLayout {
    id: root
    spacing: 8

    // Keeps the displayed position live while playback is active
    Timer {
        running: MprisController.activePlayer !== null
                 && MprisController.activePlayer.isPlaying
        interval: 1000
        repeat: true
        onTriggered: {
            if (MprisController.activePlayer)
                MprisController.activePlayer.positionChanged()
        }
    }

    // ── Media present ─────────────────────────────────────────────────────────
    ColumnLayout {
        visible: MprisController.activePlayer !== null
        Layout.fillWidth: true
        spacing: 8

        // Album art (16:9-ish)
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: width * 0.56
            radius: Appearance.rounding.normal
            color: Appearance.colors.colLayer2
            clip: true

            Image {
                anchors.fill: parent
                source: MprisController.activePlayer?.trackArtUrl ?? ""
                fillMode: Image.PreserveAspectCrop
                cache: false
                asynchronous: true
            }

            MaterialSymbol {
                anchors.centerIn: parent
                visible: !MprisController.activePlayer || !MprisController.activePlayer.trackArtUrl
                text: "music_note"
                iconSize: 40
                color: Appearance.colors.colSubtext
            }
        }

        // Title
        StyledText {
            Layout.fillWidth: true
            text: MprisController.activePlayer?.trackTitle ?? Translation.tr("Untitled")
            font.pixelSize: Appearance.font.pixelSize.small
            font.weight: Font.DemiBold
            color: Appearance.colors.colOnLayer1
            elide: Text.ElideRight
        }

        // Artist
        StyledText {
            Layout.fillWidth: true
            text: MprisController.activePlayer?.trackArtist ?? ""
            font.pixelSize: Appearance.font.pixelSize.smaller
            color: Appearance.colors.colSubtext
            elide: Text.ElideRight
        }

        // Position text
        StyledText {
            text: {
                const p = MprisController.activePlayer;
                if (!p) return "";
                return `${StringUtils.friendlyTimeForSeconds(p.position)} / ${StringUtils.friendlyTimeForSeconds(p.length)}`;
            }
            font.pixelSize: Appearance.font.pixelSize.smaller
            color: Appearance.colors.colSubtext
        }

        // Progress / seek bar
        Item {
            Layout.fillWidth: true
            implicitHeight: Math.max(seekLoader.implicitHeight, progressLoader.implicitHeight, 16)

            // Seekable: interactive wavy slider
            Loader {
                id: seekLoader
                anchors.fill: parent
                active: MprisController.activePlayer?.canSeek ?? false
                sourceComponent: StyledSlider {
                    configuration: StyledSlider.Configuration.Wavy
                    highlightColor: Appearance.colors.colPrimary
                    trackColor:     Appearance.colors.colLayer2
                    handleColor:    Appearance.colors.colPrimary
                    value: {
                        const p = MprisController.activePlayer;
                        return (p && p.length) ? p.position / p.length : 0;
                    }
                    onMoved: {
                        const p = MprisController.activePlayer;
                        if (p) p.position = value * p.length;
                    }
                }
            }

            // Non-seekable: animated wavy progress bar
            Loader {
                id: progressLoader
                anchors {
                    verticalCenter: parent.verticalCenter
                    left: parent.left
                    right: parent.right
                }
                active: !(MprisController.activePlayer?.canSeek ?? false)
                sourceComponent: StyledProgressBar {
                    wavy: MprisController.activePlayer?.isPlaying ?? false
                    highlightColor: Appearance.colors.colPrimary
                    trackColor:     Appearance.colors.colLayer2
                    value: {
                        const p = MprisController.activePlayer;
                        return (p && p.length) ? p.position / p.length : 0;
                    }
                }
            }
        }

        // Transport controls
        RowLayout {
            Layout.fillWidth: true
            spacing: 4

            Item { Layout.fillWidth: true }

            RippleButton {
                implicitWidth: 32; implicitHeight: 32
                buttonRadius: 16
                colBackground: "transparent"
                colBackgroundHover: Appearance.colors.colLayer1Hover
                colRipple: Appearance.colors.colPrimaryContainerActive
                downAction: () => MprisController.activePlayer?.previous()
                contentItem: MaterialSymbol {
                    text: "skip_previous"
                    iconSize: Appearance.font.pixelSize.large
                    color: Appearance.colors.colOnLayer1
                    horizontalAlignment: Text.AlignHCenter
                }
            }

            RippleButton {
                implicitWidth: 40; implicitHeight: 40
                buttonRadius: MprisController.activePlayer?.isPlaying
                              ? Appearance.rounding.normal : 20
                colBackground: Appearance.colors.colPrimaryContainer
                colBackgroundHover: Appearance.colors.colLayer1Hover
                colRipple: Appearance.colors.colPrimaryContainerActive
                downAction: () => MprisController.activePlayer?.togglePlaying()
                contentItem: MaterialSymbol {
                    text: MprisController.activePlayer?.isPlaying ? "pause" : "play_arrow"
                    iconSize: Appearance.font.pixelSize.large
                    fill: 1
                    color: Appearance.colors.colOnPrimaryContainer
                    horizontalAlignment: Text.AlignHCenter
                }
            }

            RippleButton {
                implicitWidth: 32; implicitHeight: 32
                buttonRadius: 16
                colBackground: "transparent"
                colBackgroundHover: Appearance.colors.colLayer1Hover
                colRipple: Appearance.colors.colPrimaryContainerActive
                downAction: () => MprisController.activePlayer?.next()
                contentItem: MaterialSymbol {
                    text: "skip_next"
                    iconSize: Appearance.font.pixelSize.large
                    color: Appearance.colors.colOnLayer1
                    horizontalAlignment: Text.AlignHCenter
                }
            }

            Item { Layout.fillWidth: true }
        }
    }

    // ── No media placeholder ──────────────────────────────────────────────────
    Rectangle {
        visible: MprisController.activePlayer === null
        Layout.fillWidth: true
        Layout.preferredHeight: 120
        radius: Appearance.rounding.normal
        color: Appearance.colors.colLayer2
        border { width: 1; color: Appearance.colors.colLayer0Border }

        ColumnLayout {
            anchors.centerIn: parent
            spacing: 6

            MaterialSymbol {
                Layout.alignment: Qt.AlignHCenter
                text: "music_off"
                iconSize: 28
                color: Appearance.colors.colSubtext
            }

            StyledText {
                Layout.alignment: Qt.AlignHCenter
                text: Translation.tr("No media playing")
                color: Appearance.colors.colSubtext
                font.pixelSize: Appearance.font.pixelSize.smaller
                font.weight: Font.DemiBold
            }
        }
    }
}
