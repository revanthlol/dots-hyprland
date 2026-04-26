pragma ComponentBehavior: Bound
import qs.modules.common
import qs.modules.common.widgets
import qs.services
import qs.modules.ii.centerDashboard.calendar
import QtQuick
import QtQuick.Layouts

Rectangle {
    id: root
    radius: Appearance.rounding.normal
    color: Appearance.colors.colLayer1
    clip: true
    implicitHeight: collapsed ? (collapsedRow.implicitHeight + 20) : 350

    property bool collapsed: Persistent.states.sidebar.bottomGroup.collapsed

    Behavior on implicitHeight {
        NumberAnimation {
            duration: Appearance.animation.elementMove.duration
            easing.type: Appearance.animation.elementMove.type
            easing.bezierCurve: Appearance.animation.elementMove.bezierCurve
        }
    }

    function setCollapsed(state) {
        Persistent.states.sidebar.bottomGroup.collapsed = state;
        if (collapsed) {
            calendarContent.opacity = 0;
        } else {
            collapsedRow.opacity = 0;
        }
        collapseCleanFadeTimer.start();
    }

    Timer {
        id: collapseCleanFadeTimer
        interval: Appearance.animation.elementMove.duration / 2
        repeat: false
        onTriggered: {
            if (collapsed)
                collapsedRow.opacity = 1;
            else
                calendarContent.opacity = 1;
        }
    }

    // Collapsed row — just shows date + expand button
    RowLayout {
        id: collapsedRow
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: 10
        opacity: collapsed ? 1 : 0
        visible: opacity > 0
        Behavior on opacity {
            NumberAnimation { duration: Appearance.animation.elementMove.duration / 2 }
        }

        CalendarHeaderButton {
            forceCircle: true
            downAction: () => root.setCollapsed(false)
            contentItem: MaterialSymbol {
                text: "keyboard_arrow_down"
                iconSize: Appearance.font.pixelSize.larger
                horizontalAlignment: Text.AlignHCenter
                color: Appearance.colors.colOnLayer1
            }
        }

        StyledText {
            Layout.fillWidth: true
            Layout.leftMargin: 8
            text: DateTime.collapsedCalendarFormat
            font.pixelSize: Appearance.font.pixelSize.large
            color: Appearance.colors.colOnLayer1
        }
    }

    // Expanded calendar
    Item {
        id: calendarContent
        anchors.fill: parent
        anchors.margins: 8
        opacity: collapsed ? 0 : 1
        visible: opacity > 0
        Behavior on opacity {
            NumberAnimation { duration: Appearance.animation.elementMove.duration / 2 }
        }

        CalendarHeaderButton {
            id: collapseBtn
            anchors.top: parent.top
            anchors.left: parent.left
            forceCircle: true
            downAction: () => root.setCollapsed(true)
            contentItem: MaterialSymbol {
                text: "keyboard_arrow_up"
                iconSize: Appearance.font.pixelSize.larger
                horizontalAlignment: Text.AlignHCenter
                color: Appearance.colors.colOnLayer1
            }
        }

        CalendarWidget {
            anchors.fill: parent
            anchors.topMargin: collapseBtn.height + 4
        }
    }
}
