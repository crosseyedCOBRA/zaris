import QtQuick
import Quickshell.Io

// RAM usage percent - originally just for Control Center's vertical gauge
// stack (see ROADMAP.md), now also a real bar module (ModulesConfig's
// "ram") - gained the same self-contained icon+text Row CpuLoad.qml
// already had both uses for, embedded here with visible: false for the
// gauge (see ControlCenter.qml's own memSource) exactly like CpuLoad
// itself already is. Mirrors CpuLoad.qml's own /proc-based polling style:
// MemAvailable (not MemFree - MemFree alone doesn't count reclaimable
// cache/buffers as "available", which would read as a permanently
// near-full bar even at idle, the same distinction `free -h`'s own
// "available" column exists to fix) against MemTotal from /proc/meminfo.
Row {
    id: root

    property color textColor: "white"
    property real percent: 0

    spacing: 4

    NText {
        text: "󰍛" // nf-md-memory
        color: root.textColor
        pointSize: Style.fontSizeL
    }

    NText {
        text: Math.round(root.percent) + "%"
        color: root.textColor
        pointSize: Style.fontSizeL
    }

    Process {
        id: reader
        command: ["sh", "-c", "grep -E '^(MemTotal|MemAvailable):' /proc/meminfo"]
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = this.text.trim().split("\n")
                let total = 0
                let available = 0
                for (const line of lines) {
                    const m = line.match(/^(\w+):\s+(\d+)/)
                    if (!m)
                        continue
                    if (m[1] === "MemTotal")
                        total = Number(m[2])
                    else if (m[1] === "MemAvailable")
                        available = Number(m[2])
                }
                if (total > 0)
                    root.percent = ((total - available) / total) * 100
            }
        }
    }

    Timer {
        interval: 5000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: reader.running = true
    }
}
