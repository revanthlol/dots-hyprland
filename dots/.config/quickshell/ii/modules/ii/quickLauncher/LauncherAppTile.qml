pragma ComponentBehavior: Bound

import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets

// App grid tile delegate.
RippleButton {
    id: root
    required property var entry
    required property bool selected
    buttonRadius: Appearance.rounding.normal
    colBackground: selected
        ? Appearance.colors.colPrimaryContainer
        : Appearance.colors.colLayer1
    colBackgroundHover: Appearance.colors.colPrimaryContainer
    colRipple:          Appearance.colors.colPrimaryContainerActive

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 8
        spacing: 6

        IconImage {
            Layout.alignment: Qt.AlignHCenter
            width: 40; height: 40
            source: Quickshell.iconPath(
                (root.entry && root.entry.icon) ? root.entry.icon : "",
                "application-x-executable")
        }

        StyledText {
            Layout.fillWidth: true
            Layout.fillHeight: true
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignTop
            text: root.entry ? root.entry.name : ""
            color: root.selected
                ? Appearance.colors.colOnPrimaryContainer
                : Appearance.colors.colOnLayer1
            elide: Text.ElideRight
            maximumLineCount: 2
            wrapMode: Text.Wrap
            font.pixelSize: Appearance.font.pixelSize.smaller
        }
    }
}
