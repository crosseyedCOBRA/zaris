import QtQuick
import Quickshell.Services.Pipewire

// Bar icon showing only mute state (matching Noctalia's own bar - a bare
// speaker/muted-speaker icon, no percentage). Left-click opens
// AudioMixerPanel.qml, a small popup with Output/Input sliders, per-app
// volume, and output/input device selection (the same AudioMixer.qml
// content Settings' own Audio tab shows) - this used to launch `pavucontrol`
// directly; ControlCenter.qml's own audio section (Output/Input sliders
// only, no device list or per-app mixing) still exists separately and is
// unaffected by this change. Right-click still just toggles mute, unchanged.
// A real ModulesConfig module ("volume") like everything else in the bar -
// used to be hardcoded to ignore that entry entirely and always render,
// which read as a real bug once Settings' toggle/reorder controls
// existed and visibly did nothing for it (see ROADMAP.md). Defaults to
// enabled, section "right", high order - same visible-by-default bar
// icon as before, just genuinely responsive to Settings now. Unrelated
// to ControlCenter.qml's own separate Output/Input audio section, which
// still exists independently either way.
Item {
    id: root

    property color textColor: "white"

    readonly property PwNode sink: Pipewire.defaultAudioSink
    PwObjectTracker { objects: root.sink ? [root.sink] : [] }

    visible: root.sink && root.sink.ready
    implicitWidth: icon.implicitWidth
    implicitHeight: icon.implicitHeight

    NText {
        id: icon
        text: (root.sink && root.sink.ready && root.sink.audio.muted) ? "󰖁" : ""
        color: root.textColor
        pointSize: Style.fontSizeL
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: mouse => {
            if (!root.sink || !root.sink.ready)
                return

            if (mouse.button === Qt.LeftButton) {
                AudioMixerPanelState.anchorItem = root
                AudioMixerPanelState.visible = !AudioMixerPanelState.visible
            } else if (mouse.button === Qt.RightButton)
                root.sink.audio.muted = !root.sink.audio.muted
        }
    }
}
