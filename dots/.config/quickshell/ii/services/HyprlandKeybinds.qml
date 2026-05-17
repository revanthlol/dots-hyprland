pragma Singleton
pragma ComponentBehavior: Bound

import qs.modules.common
import qs.modules.common.functions
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland

/**
 * A service that provides access to Hyprland keybinds.
 * It parses the Lua keybind files used by this repo and exposes the same tree
 * structure consumed by the cheatsheet UI.
 */
Singleton {
    id: root

    readonly property string keybindParserPath: FileUtils.trimFileProtocol(`${Directories.scriptPath}/hyprland/get_keybinds.py`)
    readonly property string defaultKeybindConfigPath: FileUtils.trimFileProtocol(`${Directories.config}/hypr/hyprland/keybinds.lua`)
    readonly property string userKeybindConfigPath: FileUtils.trimFileProtocol(`${Directories.config}/hypr/custom/keybinds.lua`)
    property var defaultKeybinds: ({ "children": [] })
    property var userKeybinds: ({ "children": [] })
    property var keybinds: ({
        children: [
            ...(defaultKeybinds.children ?? []),
            ...(userKeybinds.children ?? []),
        ]
    })

    function reload() {
        getDefaultKeybinds.running = true
        getUserKeybinds.running = true
    }

    Connections {
        target: Hyprland

        function onRawEvent(event) {
            if (event.name == "configreloaded") {
                root.reload()
            }
        }
    }

    Process {
        id: getDefaultKeybinds
        running: true
        command: [root.keybindParserPath, "--path", root.defaultKeybindConfigPath]

        stdout: StdioCollector {
            id: defaultKeybindsCollector
            onStreamFinished: {
                try {
                    root.defaultKeybinds = JSON.parse(defaultKeybindsCollector.text)
                } catch (e) {
                    console.error("[HyprlandKeybinds] Error parsing default keybinds:", e)
                    root.defaultKeybinds = ({ "children": [] })
                }
            }
        }
    }

    Process {
        id: getUserKeybinds
        running: true
        command: [root.keybindParserPath, "--path", root.userKeybindConfigPath]

        stdout: StdioCollector {
            id: userKeybindsCollector
            onStreamFinished: {
                try {
                    root.userKeybinds = JSON.parse(userKeybindsCollector.text)
                } catch (e) {
                    console.error("[HyprlandKeybinds] Error parsing user keybinds:", e)
                    root.userKeybinds = ({ "children": [] })
                }
            }
        }
    }
}
