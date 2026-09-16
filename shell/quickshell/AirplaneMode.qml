import QtQuick

// Airplane mode toggle: `nmcli networking off/on` disables/re-enables
// every network interface at once - see AirplaneModeState.qml's own
// header comment for why that's the right single command rather than
// toggling wifi radio + ethernet separately. Same simple on/off pattern
// as StayAwake.qml/NightLight.qml/Dnd.qml, one fixed glyph with
// color-only state (no text label).
//
// `toggle()` is exposed (see StayAwake.qml's header comment for the full
// reasoning) so ControlCenter.qml's quick-toggle tile can drive this from
// its own full-tile MouseArea instead of just this component's small
// icon; `clickable: false` disables this component's own internal
// MouseArea for that case, avoiding a double-toggle.
Item {
    id: root

    property color textColor: "white"
    property color activeColor: "white"
    property bool clickable: true
    // Overridable - see NetworkToggle.qml's own pointSize comment.
    property real pointSize: Style.fontSizeL

    function toggle() {
        AirplaneModeState.toggle()
    }

    implicitWidth: icon.implicitWidth
    implicitHeight: icon.implicitHeight

    NText {
        id: icon
        text: "\uf072"
        color: AirplaneModeState.active ? root.activeColor : root.textColor
        pointSize: root.pointSize
    }

    MouseArea {
        anchors.fill: parent
        enabled: root.clickable
        onClicked: root.toggle()
    }
}
