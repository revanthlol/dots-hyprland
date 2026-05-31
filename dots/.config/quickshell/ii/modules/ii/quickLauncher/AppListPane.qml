pragma ComponentBehavior: Bound

import qs.modules.common
import qs.modules.common.widgets
import qs.services
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell

// Right pane: search field + immediate rofi-style app list/grid.
// All stateful data flows in via required properties; updates flow out via signals.
Item {
    id: root
    focus: true

    // ── Inputs ────────────────────────────────────────────────────────────────
    required property var    visibleApps
    required property string query
    required property int    selectedIndex
    required property bool   gridView
    required property int    sortMode

    // ── Outputs ───────────────────────────────────────────────────────────────
    signal queryModified(string q)
    signal selectedIndexModified(int idx)
    signal gridViewModified(bool gv)
    signal sortModeModified(int m)
    signal appExecuted(var entry)
    signal closeRequested()

    // Called by the parent after the panel opens (ensures keyboard focus)
    function focusSearch() {
        searchField.forceActiveFocus();
        searchField.selectAll();
    }

    // Sync query change from parent programmatically
    onQueryChanged: {
        if (searchField.text !== root.query) {
            searchField.text = root.query;
        }
    }

    // Root-level keyboard navigation listener!
    // This allows arrows/Vim/Alt shortcuts to work regardless of which button currently holds active focus,
    // and seamlessly types into the search bar while automatically recovering focus!
    Keys.onPressed: event => {
        const cols = root.gridView
            ? Math.max(1, Math.floor(appGrid.width / appGrid.cellWidth))
            : 1;
        const n = root.visibleApps.length;

        // Read modifiers
        const isCtrl = event.modifiers & Qt.ControlModifier;
        const isShift = event.modifiers & Qt.ShiftModifier;
        const isAlt = event.modifiers & Qt.AltModifier;

        // Alt + [1-9] shortcut to execute app directly
        if (isAlt && event.key >= Qt.Key_1 && event.key <= Qt.Key_9) {
            const directIndex = event.key - Qt.Key_1;
            if (directIndex < n) {
                root.selectedIndexModified(directIndex);
                root.appExecuted(root.visibleApps[directIndex]);
                event.accepted = true;
                return;
            }
        }

        let key = event.key;
        if (isCtrl) {
            if (key === Qt.Key_N || key === Qt.Key_J) {
                key = Qt.Key_Down;
            } else if (key === Qt.Key_P || key === Qt.Key_K) {
                key = Qt.Key_Up;
            } else if (key === Qt.Key_L) {
                key = Qt.Key_Right;
            } else if (key === Qt.Key_H) {
                key = Qt.Key_Left;
            } else if (key === Qt.Key_G) {
                root.gridViewModified(!root.gridView);
                event.accepted = true;
                return;
            } else if (key === Qt.Key_S) {
                root.sortModeModified(root.sortMode === 0 ? 1 : 0);
                event.accepted = true;
                return;
            }
        }

        switch (key) {
            case Qt.Key_Down:
                root.selectedIndexModified(Math.min(n - 1, root.selectedIndex + cols));
                event.accepted = true; break;
            case Qt.Key_Up:
                root.selectedIndexModified(Math.max(0, root.selectedIndex - cols));
                event.accepted = true; break;
            case Qt.Key_Right:
                if (root.gridView) {
                    root.selectedIndexModified(Math.min(n - 1, root.selectedIndex + 1));
                    event.accepted = true;
                } break;
            case Qt.Key_Left:
                if (root.gridView) {
                    root.selectedIndexModified(Math.max(0, root.selectedIndex - 1));
                    event.accepted = true;
                } break;
            case Qt.Key_PageDown:
                root.selectedIndexModified(Math.min(n - 1, root.selectedIndex + (root.gridView ? 12 : 8)));
                event.accepted = true; break;
            case Qt.Key_PageUp:
                root.selectedIndexModified(Math.max(0, root.selectedIndex - (root.gridView ? 12 : 8)));
                event.accepted = true; break;
            case Qt.Key_Return:
            case Qt.Key_Enter:
                // Only execute if focus is on searchField (so buttons keep their standard Enter execution)
                if (searchField.activeFocus) {
                    if (n > 0) {
                        root.appExecuted(root.visibleApps[root.selectedIndex]);
                    }
                    event.accepted = true;
                } break;
            case Qt.Key_Escape:
                root.closeRequested();
                event.accepted = true; break;
        }

        // If focus is on a button and the user starts typing, automatically force focus back to search bar
        // and capture the keystrokes so typing is continuous and never lost!
        if (!event.accepted && !isCtrl && !isAlt && event.text.length > 0) {
            if (!searchField.activeFocus) {
                searchField.forceActiveFocus();
                searchField.text += event.text;
                event.accepted = true;
            }
        }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // ── Search bar ────────────────────────────────────────────────────────────
        RowLayout {
            Layout.fillWidth: true
            Layout.topMargin: 14
            Layout.leftMargin: 14
            Layout.rightMargin: 14
            Layout.bottomMargin: 8
            spacing: 8

            // Custom curved pill-shaped search container with animated focus borders
            Rectangle {
                id: searchBarContainer
                Layout.fillWidth: true
                implicitHeight: 44
                color: Appearance.colors.colLayer1
                border {
                    width: 1.5
                    color: searchField.activeFocus
                           ? Appearance.colors.colPrimary
                           : Appearance.colors.colLayer0Border
                }
                radius: height / 2
                clip: true

                Behavior on border.color {
                    ColorAnimation { duration: 150 }
                }

                RowLayout {
                    anchors.fill: parent
                    spacing: 8
                    anchors.leftMargin: 14
                    anchors.rightMargin: 14

                    MaterialSymbol {
                        Layout.alignment: Qt.AlignVCenter
                        text: "search"
                        iconSize: 20
                        color: searchField.activeFocus
                               ? Appearance.colors.colPrimary
                               : Appearance.colors.colSubtext

                        Behavior on color { ColorAnimation { duration: 150 } }
                    }

                    TextInput {
                        id: searchField
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignVCenter

                        // Explicit focus navigation loop
                        KeyNavigation.tab: clearButton.visible ? clearButton : sortButton
                        KeyNavigation.backtab: viewButton

                        text: root.query
                        color: Appearance.colors.colOnLayer0
                        selectionColor: Appearance.colors.colPrimaryContainerActive
                        selectedTextColor: Appearance.colors.colOnPrimaryContainer

                        font {
                            family: Appearance.font.family.main
                            pixelSize: Appearance?.font.pixelSize.small ?? 15
                        }

                        selectByMouse: true
                        clip: true

                        onTextChanged: {
                            if (root.query !== text) {
                                root.queryModified(text);
                            }
                        }

                        // Placeholder
                        StyledText {
                            anchors.fill: parent
                            verticalAlignment: Text.AlignVCenter
                            text: Translation.tr("Search apps…")
                            color: Appearance.colors.colSubtext
                            font: parent.font
                            visible: parent.text.length === 0
                        }
                    }

                    // A clear text button inside the search pill (Better UX)
                    RippleButton {
                        id: clearButton
                        Layout.alignment: Qt.AlignVCenter
                        implicitWidth: 24; implicitHeight: 24
                        activeFocusOnTab: true // Allow tab focus traversal
                        
                        // Explicit focus navigation loop
                        KeyNavigation.tab: sortButton
                        KeyNavigation.backtab: searchField

                        buttonRadius: 12
                        visible: searchField.text.length > 0
                        colBackground: "transparent"
                        colBackgroundHover: Appearance.colors.colLayer1Hover
                        colRipple: Appearance.colors.colPrimaryContainerActive
                        onClicked: {
                            searchField.text = "";
                            root.queryModified("");
                            searchField.forceActiveFocus();
                        }
                        contentItem: MaterialSymbol {
                            anchors.centerIn: parent
                            text: "close"
                            iconSize: 14
                            color: Appearance.colors.colSubtext
                        }
                    }
                }
            }

            IconToolbarButton {
                id: sortButton
                implicitHeight: 44; implicitWidth: 44
                Layout.fillHeight: false
                activeFocusOnTab: true // Allow tab focus traversal

                // Explicit focus navigation loop
                KeyNavigation.tab: viewButton
                KeyNavigation.backtab: clearButton.visible ? clearButton : searchField

                text: root.sortMode === 0 ? "sort_by_alpha" : "sort"
                toggled: root.sortMode === 1
                StyledToolTip { text: root.sortMode === 0
                    ? Translation.tr("Sort by name")
                    : Translation.tr("Sort by id") }
                onClicked: {
                    root.sortModeModified(root.sortMode === 0 ? 1 : 0);
                    searchField.forceActiveFocus();
                }
            }

            IconToolbarButton {
                id: viewButton
                implicitHeight: 44; implicitWidth: 44
                Layout.fillHeight: false
                activeFocusOnTab: true // Allow tab focus traversal

                // Explicit focus navigation loop
                KeyNavigation.tab: searchField
                KeyNavigation.backtab: sortButton

                text: root.gridView ? "view_list" : "grid_view"
                toggled: root.gridView
                StyledToolTip { text: root.gridView
                    ? Translation.tr("List view")
                    : Translation.tr("Grid view") }
                onClicked: {
                    root.gridViewModified(!root.gridView);
                    searchField.forceActiveFocus();
                }
            }
        }

        // App count
        StyledText {
            Layout.fillWidth: true
            Layout.leftMargin: 14
            Layout.rightMargin: 14
            Layout.bottomMargin: 6
            text: `${root.visibleApps.length} ${Translation.tr("apps")}`
            color: Appearance.colors.colSubtext
            font.pixelSize: Appearance.font.pixelSize.small
        }

        // ── App list / grid ───────────────────────────────────────────────────────
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.leftMargin: 8
            Layout.rightMargin: 8
            Layout.bottomMargin: 8

            // List view
            ListView {
                id: appList
                anchors.fill: parent
                visible: !root.gridView
                clip: true
                spacing: 2
                model: root.visibleApps
                currentIndex: root.selectedIndex
                onCurrentIndexChanged: positionViewAtIndex(currentIndex, ListView.Contain)
                boundsBehavior: Flickable.StopAtBounds
                ScrollBar.vertical: StyledScrollBar {}
                delegate: LauncherAppRow {
                    required property var modelData
                    required property int index
                    width: appList.width
                    entry: modelData
                    selected: index === root.selectedIndex
                    onClicked: {
                        root.selectedIndexModified(index);
                        root.appExecuted(modelData);
                    }
                }
            }

            // Grid view
            GridView {
                id: appGrid
                anchors.fill: parent
                visible: root.gridView
                clip: true
                model: root.visibleApps
                currentIndex: root.selectedIndex
                onCurrentIndexChanged: positionViewAtIndex(currentIndex, GridView.Contain)
                cellWidth:  Math.max(120, width / Math.max(3, Math.floor(width / 140)))
                cellHeight: 108
                boundsBehavior: Flickable.StopAtBounds
                ScrollBar.vertical: StyledScrollBar {}
                delegate: LauncherAppTile {
                    required property var modelData
                    required property int index
                    width: appGrid.cellWidth - 8
                    height: appGrid.cellHeight - 8
                    entry: modelData
                    selected: index === root.selectedIndex
                    onClicked: {
                        root.selectedIndexModified(index);
                        root.appExecuted(modelData);
                    }
                }
            }

            PagePlaceholder {
                anchors.centerIn: parent
                visible: root.visibleApps.length === 0
                icon: "search_off"
                title: Translation.tr("No apps found")
            }
        }
    }
}
