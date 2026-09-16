pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Shared "airplane mode" flag - `nmcli networking off/on`, NetworkManager's
// own single command for disabling every network interface at once (wifi,
// ethernet, wwan, everything), rather than toggling the wifi radio and
// disconnecting ethernet as two separate steps the way NetworkToggle.qml/
// WifiToggle.qml each handle their own device independently. Same
// shared-singleton reasoning as DndState.qml/StayAwakeState.qml: this is
// global machine state, not per-monitor, and can be changed by something
// other than this toggle (another `nmcli` call, NetworkManager's own
// applet if one's ever added) - queried once at startup so the icon
// reflects reality rather than assuming "networking enabled".
QtObject {
    id: root

    property bool active: false

    function toggle() {
        root.active = !root.active
        Quickshell.execDetached(["nmcli", "networking", root.active ? "off" : "on"])
    }

    Component.onCompleted: queryProc.running = true

    property Process queryProc: Process {
        id: queryProc
        command: ["nmcli", "networking"]
        stdout: StdioCollector {
            onStreamFinished: root.active = this.text.trim() === "disabled"
        }
    }
}
