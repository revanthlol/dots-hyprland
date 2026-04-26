import qs.services
import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import Quickshell.Io

AndroidQuickToggleButton {
    id: root
    buttonText: recording ? Translation.tr("Stop") : Translation.tr("Record")
    buttonIcon: recording ? "stop_circle" : "radio_button_checked"
    toggled: recording

    property bool recording: false

    Process {
        id: recordProc
        command: ["bash", "-c", "~/.config/quickshell/ii/scripts/videos/record.sh"]
        running: false
    }

    onClicked: {
        if (root.recording) {
            recordProc.signal(Process.SIGINT)
            root.recording = false
        } else {
            recordProc.running = true
            root.recording = true
        }
    }

    StyledToolTip {
        text: root.recording ? Translation.tr("Stop recording") : Translation.tr("Record screen")
    }
}
