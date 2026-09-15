import QtQuick
import Quickshell

// Desktop widget #1 (see ROADMAP.md's Noctalia desktop-widgets entry):
// a large clock sitting directly on the wallpaper, always below every
// other window - windowrule=float + alwaysbottom + topleft,title:^DesktopClock$
// in zaris.conf (the "alwaysbottom" rule is new, WM-side, see
// reassertAlwaysOnBottom() in windowManager.cpp). No background box at
// all, deliberately - reads as part of the desktop, not another panel.
//
// Fixed top-left position for now, not drag-to-reposition like Noctalia's
// own version (which saves per-widget position/scale) - a real follow-up,
// not silently dropped; matches Dock's own "static default position for
// now" precedent (see its own history in ROADMAP.md).
//
// visible is gated by DesktopWidgetsConfig.isEnabled("clock") - Settings'
// "Desktop Widgets" category has the on/off toggle.
FloatingWindow {
    id: root

    visible: DesktopWidgetsConfig.isEnabled("clock")
    title: "DesktopClock"
    color: "transparent"

    implicitWidth: timeText.implicitWidth + Style.margin2L
    implicitHeight: timeText.implicitHeight + dateText.implicitHeight + Style.marginS

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    Column {
        anchors.fill: parent
        spacing: Style.marginXS

        NText {
            id: timeText
            text: Qt.formatDateTime(clock.date, DateTimeConfig.timeFormat)
            pointSize: Style.fontSizeDesktopXL
            font.weight: Style.fontWeightBold
            color: Colors.text
        }

        NText {
            id: dateText
            text: Qt.formatDateTime(clock.date, DateTimeConfig.dateFormat)
            pointSize: Style.fontSizeL
            font.weight: Style.fontWeightMedium
            color: Colors.textMuted
        }
    }
}
