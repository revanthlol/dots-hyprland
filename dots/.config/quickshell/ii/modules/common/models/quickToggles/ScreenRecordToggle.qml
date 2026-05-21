import QtQuick
import Quickshell
import qs
import qs.services
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets

QuickToggleModel {
    name: Translation.tr("Screen record")
    hasStatusText: false
    toggled: false
    icon: "radio_button_checked"

    mainAction: () => {
        GlobalStates.dashboardOpen = false;
        delayedActionTimer.start();
    }
    Timer {
        id: delayedActionTimer
        interval: 300
        repeat: false
        onTriggered: {
            Quickshell.execDetached(["qs", "-p", Quickshell.shellPath(""), "ipc", "call", "region", "recordWithSound"]);
        }
    }

    tooltipText: Translation.tr("Screen record")
}
