import QtQuick

// Battery/power-device status bar icon - shows a tiered glyph plus the
// percentage, colored to flag low/critical charge. Hides itself entirely
// when there's no present battery device at all (this desktop's own
// internal power has none - see BatteryService.qml's header comment on
// what UPower device this was verified against), same "vanish rather than
// show empty" convention as MediaWidget.qml/NightLight.qml's tray label.
Item {
    id: root

    property color textColor: "white"
    property color warningColor: "orange"
    property color criticalColor: "red"

    readonly property bool present: BatteryService.batteryPresent
    readonly property color effectiveColor: {
        if (BatteryService.isCriticalBattery(BatteryService.primaryDevice))
            return root.criticalColor
        if (BatteryService.isLowBattery(BatteryService.primaryDevice))
            return root.warningColor
        return root.textColor
    }

    // Collapses to 0 when there's no battery, not just invisible - see
    // BrightnessIndicator.qml's own comment on why (an invisible item
    // still reserves its implicitWidth/Height inside a Row otherwise,
    // rendering as a blank gap the size of the icon+percentage text).
    implicitWidth: root.present ? row.implicitWidth : 0
    implicitHeight: root.present ? row.implicitHeight : 0

    Row {
        id: row
        spacing: 4

        NText {
            text: BatteryService.batteryIcon
            color: root.effectiveColor
            pointSize: Style.fontSizeL
        }

        NText {
            text: BatteryService.batteryPercentage + "%"
            color: root.effectiveColor
            pointSize: Style.fontSizeL
        }
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        onEntered: TooltipService.show(root, BatteryService.getTimeRemainingText(BatteryService.primaryDevice))
        onExited: TooltipService.hide()
    }
}
