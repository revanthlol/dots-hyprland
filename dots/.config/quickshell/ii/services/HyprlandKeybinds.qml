pragma Singleton
pragma ComponentBehavior: Bound

import qs.modules.common
import qs.modules.common.functions
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland

/**
 * Parses the repo's Lua keybind files and exposes the flat Hyprland bind shape
 * consumed by the end4 cheatsheet UI.
 */
Singleton {
    id: root

    readonly property string keybindParserPath: FileUtils.trimFileProtocol(`${Directories.scriptPath}/hyprland/get_keybinds.py`)
    readonly property string defaultKeybindConfigPath: FileUtils.trimFileProtocol(`${Directories.config}/hypr/hyprland/keybinds.lua`)
    readonly property string userKeybindConfigPath: FileUtils.trimFileProtocol(`${Directories.config}/hypr/custom/keybinds.lua`)
    property var defaultKeybindTree: ({ "children": [] })
    property var userKeybindTree: ({ "children": [] })
    property var keybinds: flattenTrees([defaultKeybindTree, userKeybindTree])
    property var keybindCategories: categoriesFor(keybinds)

    function reload() {
        getDefaultKeybinds.running = true;
        getUserKeybinds.running = true;
    }

    function modToMask(mod) {
        switch (mod) {
        case "Shift": return 1 << 0;
        case "Ctrl": return 1 << 2;
        case "Alt": return 1 << 3;
        case "Super": return 1 << 6;
        default: return 0;
        }
    }

    function modsToMask(mods) {
        return (mods ?? []).reduce((mask, mod) => mask | modToMask(mod), 0);
    }

    function flattenSection(section, fallbackCategory) {
        const category = section?.name?.length > 0 ? section.name : fallbackCategory;
        let result = [];

        for (const bind of section?.keybinds ?? []) {
            const comment = bind.comment ?? "";
            result.push({
                modmask: modsToMask(bind.mods),
                key: bind.key ?? "",
                description: comment.includes(":") ? comment : `${category}: ${comment}`
            });
        }

        for (const child of section?.children ?? []) {
            result = result.concat(flattenSection(child, category));
        }

        return result;
    }

    function flattenTrees(trees) {
        let result = [];
        for (const tree of trees) {
            for (const section of tree?.children ?? []) {
                result = result.concat(flattenSection(section, section.name ?? ""));
            }
        }
        return result;
    }

    function categoriesFor(binds) {
        const groups = [];
        for (const bind of binds ?? []) {
            const description = bind.description ?? "";
            const group = description.substring(0, description.indexOf(":"));
            if (group.length > 0 && !groups.includes(group))
                groups.push(group);
        }
        return groups;
    }

    Connections {
        target: Hyprland

        function onRawEvent(event) {
            if (event.name == "configreloaded")
                root.reload();
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
                    root.defaultKeybindTree = JSON.parse(defaultKeybindsCollector.text);
                } catch (e) {
                    console.error("[HyprlandKeybinds] Error parsing default keybinds:", e);
                    root.defaultKeybindTree = ({ "children": [] });
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
                    root.userKeybindTree = JSON.parse(userKeybindsCollector.text);
                } catch (e) {
                    console.error("[HyprlandKeybinds] Error parsing user keybinds:", e);
                    root.userKeybindTree = ({ "children": [] });
                }
            }
        }
    }
}
