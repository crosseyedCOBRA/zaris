import QtQuick
import Quickshell

// Compact brightness bar module - icon + percentage for the primary
// monitor (same "primary" concept OSD.qml's showPrimaryBrightness()
// already uses), scroll to adjust. Only visible when brightness control
// is actually available there (ddcutil/brightnessctl/internal backlight)
// - degrades to hidden rather than a dead icon, same principle as
// BatteryIndicator's own batteryPresent gate.
// Item, not Row, at the root - a MouseArea needs to sit alongside the
// Row (anchors.fill: parent), not inside it (a Row/Positioner rejects
// anchored children entirely) - same structure as StayAwake.qml/
// NightLight.qml's own icon+label+click components.
Item {
    id: root

    property color textColor: "white"

    readonly property var monitor: BrightnessService.getMonitorForScreen(Quickshell.screens[0])
    readonly property bool available: !!root.monitor && root.monitor.brightnessControlAvailable
    // increase/decreaseBrightness() only queue the new value (applied
    // after a short debounce) rather than updating `brightness`
    // synchronously - same reasoning as OSD.qml's own read here, so a
    // scroll doesn't briefly flash the stale pre-change level.
    readonly property real level: {
        if (!root.monitor)
            return 0
        return !isNaN(root.monitor.queuedBrightness) ? root.monitor.queuedBrightness : root.monitor.brightness
    }

    visible: root.available
    implicitWidth: rowLayout.implicitWidth
    implicitHeight: rowLayout.implicitHeight

    Row {
        id: rowLayout
        spacing: 4

        NText {
            text: "" // nf-fa-sun_o
            color: root.textColor
            pointSize: Style.fontSizeL
        }

        NText {
            text: Math.round(root.level * 100) + "%"
            color: root.textColor
            pointSize: Style.fontSizeL
        }
    }

    MouseArea {
        anchors.fill: parent
        onWheel: wheel => {
            if (wheel.angleDelta.y > 0)
                BrightnessService.increaseBrightness()
            else if (wheel.angleDelta.y < 0)
                BrightnessService.decreaseBrightness()
        }
    }
}
