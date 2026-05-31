pragma ComponentBehavior: Bound

import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import QtQuick.Layouts

// A single system-stat row: icon + label + value, with an optional progress bar.
// Set `progress` to a 0.0–1.0 value to show the bar; leave at -1 to hide it.
ColumnLayout {
    required property string icon
    required property string label
    required property string value
    property bool warning: false
    property real progress: -1   // 0.0–1.0; negative = no bar

    spacing: 4

    RowLayout {
        Layout.fillWidth: true
        spacing: 8

        MaterialSymbol {
            text: icon
            iconSize: Appearance.font.pixelSize.normal
            color: warning ? Appearance.colors.colError : Appearance.colors.colPrimary
            Layout.alignment: Qt.AlignVCenter
        }

        StyledText {
            text: label
            color: Appearance.colors.colSubtext
            font.pixelSize: Appearance.font.pixelSize.smaller
            font.weight: Font.DemiBold
            Layout.alignment: Qt.AlignVCenter
            Layout.preferredWidth: 36
        }

        Item { Layout.fillWidth: true }

        StyledText {
            text: value
            color: warning ? Appearance.colors.colError : Appearance.colors.colOnLayer1
            font.pixelSize: Appearance.font.pixelSize.smaller
            font.weight: Font.Medium
            Layout.alignment: Qt.AlignVCenter
        }
    }

    // Mini progress bar – only visible when progress is in [0, 1]
    Rectangle {
        visible: progress >= 0
        Layout.fillWidth: true
        implicitHeight: 3
        radius: 2
        color: Appearance.colors.colLayer2

        Rectangle {
            width: parent.width * Math.max(0, Math.min(1, progress))
            height: parent.height
            radius: parent.radius
            color: warning ? Appearance.colors.colError : Appearance.colors.colPrimary

            Behavior on width {
                NumberAnimation { duration: 300; easing.type: Easing.OutCubic }
            }
        }
    }
}
