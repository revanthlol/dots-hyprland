pragma Singleton
pragma ComponentBehavior: Bound

import qs.modules.common
import QtQuick
import Quickshell
import Quickshell.Io

/**
 * Simple polled resource usage service with RAM, Swap, and CPU usage.
 */
Singleton {
    id: root
	property real memoryTotal: 1
	property real memoryFree: 0
	property real memoryUsed: memoryTotal - memoryFree
    property real memoryUsedPercentage: memoryUsed / memoryTotal
    property real swapTotal: 1
	property real swapFree: 0
	property real swapUsed: swapTotal - swapFree
    property real swapUsedPercentage: swapTotal > 0 ? (swapUsed / swapTotal) : 0
    property real cpuUsage: 0
    property bool cpuUsageReady: false
    property int cpuCores: 0
    property int cpuThreads: 0
    property real loadAverageOneMinute: 0
    property var previousCpuStats

    property string maxAvailableMemoryString: kbToGbString(ResourceUsage.memoryTotal)
    property string maxAvailableSwapString: kbToGbString(ResourceUsage.swapTotal)
    property string maxAvailableCpuString: "--"
    property string cpuUsageString: cpuUsageReady ? `${Math.round(cpuUsage * 100)}%` : "--"
    property string loadAverageOneMinuteString: `${loadAverageOneMinute.toFixed(2)} / ${cpuThreads || "--"}`

    readonly property int historyLength: Config?.options.resources.historyLength ?? 60
    property list<real> cpuUsageHistory: []
    property list<real> memoryUsageHistory: []
    property list<real> swapUsageHistory: []

    function kbToGbString(kb) {
        return (kb / (1024 * 1024)).toFixed(1) + " GB";
    }

    function parsePositiveInt(value) {
        const parsed = parseInt(value, 10)
        return isFinite(parsed) && parsed > 0 ? parsed : 0
    }

    function updateMemoryUsageHistory() {
        memoryUsageHistory = [...memoryUsageHistory, memoryUsedPercentage]
        if (memoryUsageHistory.length > historyLength) {
            memoryUsageHistory.shift()
        }
    }
    function updateSwapUsageHistory() {
        swapUsageHistory = [...swapUsageHistory, swapUsedPercentage]
        if (swapUsageHistory.length > historyLength) {
            swapUsageHistory.shift()
        }
    }
    function updateCpuUsageHistory() {
        cpuUsageHistory = [...cpuUsageHistory, cpuUsage]
        if (cpuUsageHistory.length > historyLength) {
            cpuUsageHistory.shift()
        }
    }
    function updateHistories() {
        updateMemoryUsageHistory()
        updateSwapUsageHistory()
        updateCpuUsageHistory()
    }

	Timer {
		interval: 1
        running: true 
        repeat: true
		onTriggered: {
            // Reload files
            fileMeminfo.reload()
            fileStat.reload()

            // Parse memory and swap usage
            const textMeminfo = fileMeminfo.text()
            memoryTotal = Number(textMeminfo.match(/MemTotal: *(\d+)/)?.[1] ?? 1)
            memoryFree = Number(textMeminfo.match(/MemAvailable: *(\d+)/)?.[1] ?? 0)
            swapTotal = Number(textMeminfo.match(/SwapTotal: *(\d+)/)?.[1] ?? 1)
            swapFree = Number(textMeminfo.match(/SwapFree: *(\d+)/)?.[1] ?? 0)

            // Parse CPU usage
            const textStat = fileStat.text()
            const loadAverageParts = fileLoadAvg.text().trim().split(/\s+/)
            loadAverageOneMinute = parseFloat(loadAverageParts[0]) || 0
            const cpuLine = textStat.match(/^cpu\s+(.+)$/m)
            if (cpuLine) {
                const stats = cpuLine[1].trim().split(/\s+/).map(Number)
                const total = stats.reduce((a, b) => a + b, 0)
                const idle = (stats[3] || 0) + (stats[4] || 0)

                if (previousCpuStats) {
                    const totalDiff = total - previousCpuStats.total
                    const idleDiff = idle - previousCpuStats.idle
                    cpuUsage = totalDiff > 0 ? Math.max(0, Math.min(1, 1 - idleDiff / totalDiff)) : cpuUsage
                    cpuUsageReady = true
                }

                previousCpuStats = { total, idle }
            }

            root.updateHistories()
            interval = Config.options?.resources?.updateInterval ?? 3000
        }
	}

	FileView { id: fileMeminfo; path: "/proc/meminfo" }
    FileView { id: fileStat; path: "/proc/stat" }
    FileView { id: fileLoadAvg; path: "/proc/loadavg" }

    Process {
        id: findCpuMaxFreqProc
        environment: ({
            LANG: "C",
            LC_ALL: "C"
        })
        command: ["bash", "-c", "lscpu | awk -F: '/^CPU max MHz:/ {gsub(/^[ \\t]+/, \"\", $2); print $2; exit} /^CPU max MHz/ {print $NF; exit}'"]
        running: true
        stdout: StdioCollector {
            id: outputCollector
            onStreamFinished: {
                const mhz = parseFloat(outputCollector.text)
                root.maxAvailableCpuString = isFinite(mhz) && mhz > 0 ? (mhz / 1000).toFixed(1) + " GHz" : "--"
            }
        }
    }

    Process {
        id: findCpuInfoProc
        environment: ({
            LANG: "C",
            LC_ALL: "C"
        })
        command: ["bash", "-c", "lscpu | awk -F: '/^Core\\(s\\) per socket:/ {gsub(/^[ \\t]+/,\"\",$2); cores=$2+0} /^Socket\\(s\\):/ {gsub(/^[ \\t]+/,\"\",$2); sockets=$2+0} /^Thread\\(s\\) per core:/ {gsub(/^[ \\t]+/,\"\",$2); threads_per_core=$2+0} /^CPU\\(s\\):/ {gsub(/^[ \\t]+/,\"\",$2); cpus=$2+0} END{real_cores=cores*sockets; if (!cpus && real_cores && threads_per_core) cpus=real_cores*threads_per_core; print real_cores; print cpus}'"]
        running: true
        stdout: StdioCollector {
            id: cpuInfoCollector
            onStreamFinished: {
                const lines = cpuInfoCollector.text.trim().split("\n");
                root.cpuCores = root.parsePositiveInt(lines[0]);
                root.cpuThreads = root.parsePositiveInt(lines[1]);
            }
        }
    }
}
