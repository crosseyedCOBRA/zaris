import QtQuick
import Quickshell
import Quickshell.Io

// VPN bar toggle - lists NetworkManager VPN-type connections (`nmcli`'s
// own TYPE field: "vpn" for plugin-based ones - OpenVPN/OpenConnect/etc -
// or "wireguard" for a native NM WireGuard connection) via the same
// Process/nmcli pattern NetworkInterfacesService.qml already established
// for the Network tab. Self-hides entirely when no VPN connection is
// configured at all - same "vanish rather than show a dead control"
// convention BatteryIndicator.qml/BrightnessIndicator.qml already use for
// missing hardware, applied here to a missing configuration instead.
//
// Deliberately a single icon, not a per-profile picker - toggles
// whichever VPN connection is currently active off, or the first
// configured one on if none are. Good enough for the common "I have one
// VPN profile" case; a real multi-profile picker (a small popup listing
// every one) is a real follow-up if this project ever has more than one
// configured VPN to actually test that against - not fully speculatively
// built here.
Item {
    id: root

    property color textColor: "white"
    property color activeColor: "white"

    property var vpnConnections: []
    readonly property var activeConnection: root.vpnConnections.find(function (c) { return c.active })
    readonly property bool hasVpn: root.vpnConnections.length > 0
    readonly property bool connected: !!root.activeConnection

    // Collapses to 0 when hidden, not just invisible - see
    // BrightnessIndicator.qml's own comment on why (an invisible item
    // still reserves its implicitWidth/Height inside a Row otherwise).
    visible: root.hasVpn
    implicitWidth: root.hasVpn ? rowLayout.implicitWidth : 0
    implicitHeight: root.hasVpn ? rowLayout.implicitHeight : 0

    Row {
        id: rowLayout
        spacing: 4

        NText {
            text: "" // nf-fa-shield
            color: root.connected ? root.activeColor : root.textColor
            pointSize: Style.fontSizeL
        }
    }

    Process {
        id: lister
        command: ["nmcli", "-t", "-f", "NAME,TYPE,ACTIVE", "connection", "show"]
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = this.text.trim().split("\n").filter(l => l.length > 0)
                root.vpnConnections = lines.map(function (line) {
                    // nmcli -t fields are colon-separated; a connection
                    // NAME can itself contain a colon (rare, but
                    // possible), so split from the right instead of the
                    // left - TYPE/ACTIVE are always the last two fields.
                    const parts = line.split(":")
                    const active = parts.pop() === "yes"
                    const type = parts.pop()
                    const name = parts.join(":")
                    return { name: name, type: type, active: active }
                }).filter(function (c) { return /vpn|wireguard/i.test(c.type) })
            }
        }
    }

    Timer {
        interval: 3000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: lister.running = true
    }

    Process {
        id: toggler
        // Re-poll shortly after toggling rather than waiting for the next
        // scheduled tick, so the icon reflects the change quickly.
        onExited: pollAfterToggle.start()
    }

    Timer {
        id: pollAfterToggle
        interval: 500
        onTriggered: lister.running = true
    }

    MouseArea {
        anchors.fill: parent
        onClicked: {
            if (root.connected) {
                toggler.command = ["nmcli", "connection", "down", root.activeConnection.name]
            } else if (root.vpnConnections.length > 0) {
                toggler.command = ["nmcli", "connection", "up", root.vpnConnections[0].name]
            } else {
                return
            }
            toggler.running = true
        }
    }
}
