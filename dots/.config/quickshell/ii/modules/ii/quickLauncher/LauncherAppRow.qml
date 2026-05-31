pragma ComponentBehavior: Bound

import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets

// App list row delegate.
RippleButton {
    id: root
    required property var entry
    required property bool selected
    implicitHeight: 52
    buttonRadius: Appearance.rounding.normal
    colBackground: selected
        ? Appearance.colors.colPrimaryContainer
        : "transparent"
    colBackgroundHover: Appearance.colors.colLayer1Hover
    colRipple:          Appearance.colors.colPrimaryContainerActive

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 10
        anchors.rightMargin: 10
        spacing: 10

        IconImage {
            Layout.alignment: Qt.AlignVCenter
            width: 32; height: 32
            source: Quickshell.iconPath(
                (root.entry && root.entry.icon) ? root.entry.icon : "",
                "application-x-executable")
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            spacing: 0

            StyledText {
                Layout.fillWidth: true
                text: root.entry ? root.entry.name : ""
                color: root.selected
                    ? Appearance.colors.colOnPrimaryContainer
                    : Appearance.colors.colOnLayer0
                font.pixelSize: Appearance.font.pixelSize.small
                elide: Text.ElideRight
            }
            StyledText {
                Layout.fillWidth: true
                visible: root.entry
                    ? ((root.entry.comment || root.entry.genericName || "").length > 0)
                    : false
                text: root.entry
                    ? (root.entry.comment || root.entry.genericName || "")
                    : ""
                color: root.selected
                    ? Appearance.colors.colOnPrimaryContainer
                    : Appearance.colors.colSubtext
                font.pixelSize: Appearance.font.pixelSize.smaller
                elide: Text.ElideRight
            }
        }

        MaterialSymbol {
            visible: root.selected
            text: "keyboard_return"
            iconSize: 18
            color: Appearance.colors.colOnPrimaryContainer
        }
    }
}
