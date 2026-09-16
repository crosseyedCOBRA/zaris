import QtQuick

// Manual "do not disturb" toggle for dunst, via `dunstctl set-paused
// toggle` - same simple on/off pattern as StayAwake.qml/NightLight.qml.
// Fulfills the Do Not Disturb quick-toggle idea from Noctalia v5's
// Control Center (see ROADMAP.md's Phase 3 section) - not a port of
// anything, dunst already has its own real pause mechanism
// (`dunstctl set-paused`/`is-paused`, confirmed via `dunstctl --help`),
// so this is just a thin bar-icon wrapper around a command dunst itself
// already provides, the same relationship `NightLight.qml` has with
// `redshift`.
//
// `toggle()` is exposed (see StayAwake.qml's header comment for the full
// reasoning) so ControlCenter.qml's quick-toggle tiles can drive this from
// their own full-tile MouseArea instead of just this component's small
// icon+label; `clickable: false` disables this component's own internal
// MouseArea for that case, avoiding a double-toggle.
Item {
    id: root

    property color textColor: "white"
    property color activeColor: "white"
    property bool clickable: true
    // Overridable - see NetworkToggle.qml's own pointSize comment.
    property real pointSize: Style.fontSizeL

    function toggle() {
        DndState.toggle()
    }

    implicitWidth: icon.implicitWidth
    implicitHeight: icon.implicitHeight

    // One fixed "bell with a line through it" glyph (fa-bell_slash,
    // already a real Do Not Disturb icon on its own) rather than
    // swapping between a plain bell and this one by state - state now
    // reads purely from color instead, same as every other toggle in
    // this row. Also used to swap in a "dnd" text label alongside the
    // icon while paused - removed per explicit request ("when turned
    // on, lets just change the color of the icon instead of writing
    // something out").
    NText {
        id: icon
        text: ""
        color: DndState.paused ? root.activeColor : root.textColor
        pointSize: root.pointSize
    }

    MouseArea {
        anchors.fill: parent
        enabled: root.clickable
        onClicked: root.toggle()
    }
}
