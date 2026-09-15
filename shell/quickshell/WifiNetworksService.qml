pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Scanned wifi network list for NetworkPanel.qml's own "Wi-Fi" tab -
// deliberately separate from WifiToggle.qml (Control Center's single
// radio-power on/off tile) and NetworkInterfacesService.qml (the live
// per-device throughput list Settings' Network tab uses) - this is the
// one place actually listing *available networks to connect to*, which
// neither of those does.
//
// `nmcli -t -f IN-USE,SIGNAL,SECURITY,SSID device wifi list` with SSID
// placed *last* and parsed as "everything after the third colon" rather
// than a plain split(":") - an SSID can itself legally contain a colon,
// and nmcli's terse mode has no field-quoting for that, only IN-USE/
// SIGNAL/SECURITY are guaranteed colon-free (a literal "*" or empty,
// a plain number, and a space-separated capability list like "WPA2",
// respectively) - the same "known-safe fields first, freeform field last"
// trick VpnToggle.qml already uses for connection NAME.
//
// "Known" (has a saved NetworkManager connection profile already, so
// reconnecting needs no password) is cross-referenced separately via
// `nmcli -t -f NAME connection show` - `device wifi list` itself has no
// such column.
Singleton {
    id: root

    property var networks: [] // [{ssid, signal, secured, inUse, known}]
    property bool scanning: false
    property string connectError: ""
    property string connectingSsid: "" // "" when nothing is mid-connect

    property var _knownNames: []

    function rescan() {
        root.scanning = true
        rescanProc.running = true
    }

    // Known (has a saved profile) -> nmcli connection up reuses the saved
    // secrets, no password needed even for a secured network. Unknown +
    // open -> nmcli device wifi connect with no password. Unknown +
    // secured -> the caller (NetworkPanel.qml's inline password field)
    // supplies one.
    function connect(ssid, known, password) {
        root.connectError = ""
        root.connectingSsid = ssid
        if (known)
            connectProc.command = ["nmcli", "connection", "up", ssid]
        else if (password && password.length > 0)
            connectProc.command = ["nmcli", "device", "wifi", "connect", ssid, "password", password]
        else
            connectProc.command = ["nmcli", "device", "wifi", "connect", ssid]
        connectProc.running = true
    }

    function disconnectCurrent() {
        const active = root.networks.find(function (n) { return n.inUse })
        if (active)
            Quickshell.execDetached(["nmcli", "connection", "down", active.ssid])
    }

    Process {
        id: knownNamesProc
        command: ["nmcli", "-t", "-f", "NAME,TYPE", "connection", "show"]
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = this.text.trim().split("\n")
                const names = []
                for (const line of lines) {
                    if (!line)
                        continue
                    // TYPE is the last field here too (a connection NAME
                    // can itself contain a colon) - same remainder trick,
                    // just with only one fixed field ahead of it.
                    const firstColon = line.indexOf(":")
                    if (firstColon < 0)
                        continue
                    const name = line.substring(0, firstColon)
                    const type = line.substring(firstColon + 1)
                    if (type === "802-11-wireless" || type === "wifi")
                        names.push(name)
                }
                root._knownNames = names
            }
        }
    }

    Process {
        id: rescanProc
        command: ["nmcli", "device", "wifi", "rescan"]
        // Rescan is fire-and-forget from nmcli's own perspective (it
        // returns immediately, the actual scan happens async in
        // NetworkManager) - listProc re-reads a moment later regardless
        // of rescanProc's own exit code, same "don't block the UI on a
        // scan trigger" reasoning most network UIs use.
        onExited: rescanSettle.start()
    }

    Timer {
        id: rescanSettle
        interval: 2000
        onTriggered: {
            knownNamesProc.running = true
            listProc.running = true
        }
    }

    Process {
        id: listProc
        command: ["nmcli", "-t", "-f", "IN-USE,SIGNAL,SECURITY,SSID", "device", "wifi", "list"]
        stdout: StdioCollector {
            onStreamFinished: {
                root.scanning = false
                const lines = this.text.trim().split("\n")
                const seen = {}
                const list = []
                for (const line of lines) {
                    if (!line)
                        continue
                    const c1 = line.indexOf(":")
                    if (c1 < 0)
                        continue
                    const c2 = line.indexOf(":", c1 + 1)
                    if (c2 < 0)
                        continue
                    const c3 = line.indexOf(":", c2 + 1)
                    if (c3 < 0)
                        continue
                    const inUse = line.substring(0, c1) === "*"
                    const signal = parseInt(line.substring(c1 + 1, c2), 10) || 0
                    const security = line.substring(c2 + 1, c3)
                    const ssid = line.substring(c3 + 1)
                    if (!ssid)
                        continue
                    // A single AP can show up once per band/BSSID - keep
                    // only the strongest-signal entry per SSID, matching
                    // every mainstream OS's own wifi picker convention of
                    // one row per network name, not one per radio.
                    if (seen[ssid] !== undefined && list[seen[ssid]].signal >= signal)
                        continue
                    const entry = {
                        ssid: ssid,
                        signal: signal,
                        secured: security !== "",
                        inUse: inUse,
                        known: root._knownNames.indexOf(ssid) !== -1
                    }
                    if (seen[ssid] !== undefined) {
                        list[seen[ssid]] = entry
                    } else {
                        seen[ssid] = list.length
                        list.push(entry)
                    }
                }
                list.sort(function (a, b) { return b.signal - a.signal })
                root.networks = list
            }
        }
    }

    Process {
        id: connectProc
        onExited: (exitCode, exitStatus) => {
            root.connectingSsid = ""
            if (exitCode !== 0)
                root.connectError = "Couldn't connect"
            root.rescan()
        }
    }

    Timer {
        interval: 15000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.rescan()
    }
}
