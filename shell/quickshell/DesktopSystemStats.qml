import QtQuick
import Quickshell

// Desktop widget #3 - CPU/RAM/CPU temp/GPU temp as a small card sitting
// directly on the wallpaper, always below every other window. Reuses
// CpuLoad.qml/HwmonSensor.qml/MemUsage.qml as hidden value sources
// (visible: false, only their live-polled .percent/.value read) exactly
// the way ControlCenter.qml's own gauge stack already does - same
// Process/Timer polling logic, not re-derived a third time.
//
// windowrule=float + alwaysbottom + topright,title:^DesktopSystemStats$
// in zaris.conf - "topright" already existed (Overflow.qml's old "More"
// chevron used it originally), Clock has top-left and Media has
// bottom-left, so this is the one remaining corner not yet claimed by
// another desktop widget.
FloatingWindow {
    id: root

    visible: DesktopWidgetsConfig.isEnabled("systemStats")
    title: "DesktopSystemStats"
    color: "transparent"

    implicitWidth: 160
    implicitHeight: statsColumn.implicitHeight + Style.margin2M

    CpuLoad {
        id: cpuSource
        visible: false
    }

    HwmonSensor {
        id: cpuTempSource
        sensorLabel: "Tctl" // k10temp CPU die sensor -- verify with
                             // `grep . /sys/class/hwmon/hwmon*/temp*_label`
                             // and adjust if different
        iconGlyph: ""
        visible: false
    }

    HwmonSensor {
        id: gpuTempSource
        sensorLabel: "edge" // amdgpu GPU sensor -- same caveat as above
        iconGlyph: ""
        visible: false
    }

    MemUsage {
        id: memSource
        visible: false
    }

    Rectangle {
        anchors.fill: parent
        radius: Style.radiusM
        color: Qt.rgba(0, 0, 0, 0.35)

        Column {
            id: statsColumn
            anchors.centerIn: parent
            width: parent.width - Style.margin2M
            spacing: Style.marginXS

            Row {
                width: parent.width
                NText { text: "CPU"; color: Colors.textMuted; pointSize: Style.fontSizeS; width: parent.width / 2 }
                NText { text: Math.round(cpuSource.percent) + "%"; color: Colors.coral; pointSize: Style.fontSizeS; width: parent.width / 2; horizontalAlignment: Text.AlignRight }
            }

            Row {
                width: parent.width
                NText { text: "RAM"; color: Colors.textMuted; pointSize: Style.fontSizeS; width: parent.width / 2 }
                NText { text: Math.round(memSource.percent) + "%"; color: Colors.teal; pointSize: Style.fontSizeS; width: parent.width / 2; horizontalAlignment: Text.AlignRight }
            }

            Row {
                width: parent.width
                NText { text: "CPU Temp"; color: Colors.textMuted; pointSize: Style.fontSizeS; width: parent.width / 2 }
                NText { text: cpuTempSource.haveReading ? Math.round(cpuTempSource.tempC) + "°" : "--"; color: Colors.blue; pointSize: Style.fontSizeS; width: parent.width / 2; horizontalAlignment: Text.AlignRight }
            }

            Row {
                width: parent.width
                NText { text: "GPU Temp"; color: Colors.textMuted; pointSize: Style.fontSizeS; width: parent.width / 2 }
                NText { text: gpuTempSource.haveReading ? Math.round(gpuTempSource.tempC) + "°" : "--"; color: Colors.blue; pointSize: Style.fontSizeS; width: parent.width / 2; horizontalAlignment: Text.AlignRight }
            }
        }
    }
}
