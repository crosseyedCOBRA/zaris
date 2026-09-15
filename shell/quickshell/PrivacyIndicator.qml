import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire

// Privacy indicator bar module - shows a mic icon while something is
// actively recording audio, a camera icon while something has a webcam
// device open. Self-hides entirely (and each sub-icon independently)
// when neither/either is inactive - same convention as every other
// self-hiding module in this file.
//
// Deliberately does NOT attempt screen-recording detection, unlike
// Noctalia's own version - X11 has no centralized, portal-mediated
// signal for "something is capturing the screen" the way Wayland's
// xdg-desktop-portal ScreenCast interface provides. An X11 capture tool
// (ffmpeg -f x11grab, OBS's own xshm source, etc.) just grabs pixels
// directly via XShm/XComposite with nothing to detect system-wide -
// building a fake/unreliable heuristic for this would be worse than not
// having it.
//
// Mic: a genuine capture stream in Pipewire.nodes - `!isSink && isStream`
// is AudioMixer.qml's own already-verified signature for "an app's
// recording stream" (as opposed to `!isSink && !isStream`, a hardware
// input *device* like the mic itself, which exists regardless of
// whether anything's actually recording from it). Existence of the
// stream node is the signal - Pipewire creates/destroys these as an
// app opens/closes its recording, not just a state flag on an
// always-present node.
//
// Camera: no equivalent Pipewire signal (webcams go through V4L2
// directly, not Pipewire, on this system) - polls `fuser` against
// /dev/video* instead. Exit code only (0 = something has it open), not
// output parsing - which process is irrelevant here, only whether one
// exists.
Item {
    id: root

    // No plain textColor - unlike every other module, these icons are
    // either shown (something's actively recording) or not shown at all,
    // never a dimmed "inactive but visible" state, so there's no muted
    // color to fall back to.
    property color micColor: "white"
    property color cameraColor: "white"

    readonly property bool micActive: Pipewire.nodes.values.some(function (n) { return !n.isSink && n.isStream })
    property bool cameraActive: false

    PwObjectTracker {
        objects: Pipewire.nodes.values
    }

    readonly property bool anyActive: root.micActive || root.cameraActive
    // Collapses to 0 when hidden, not just invisible - see
    // BrightnessIndicator.qml's own comment on why.
    visible: root.anyActive
    implicitWidth: root.anyActive ? rowLayout.implicitWidth : 0
    implicitHeight: root.anyActive ? rowLayout.implicitHeight : 0

    Row {
        id: rowLayout
        spacing: 4

        NText {
            visible: root.micActive
            text: "" // nf-fa-microphone
            color: root.micColor
            pointSize: Style.fontSizeL
        }

        NText {
            visible: root.cameraActive
            text: "" // nf-fa-camera
            color: root.cameraColor
            pointSize: Style.fontSizeL
        }
    }

    Process {
        id: camChecker
        command: ["sh", "-c", "fuser /dev/video* >/dev/null 2>&1"]
        onExited: (exitCode, exitStatus) => {
            root.cameraActive = exitCode === 0
        }
    }

    Timer {
        interval: 2000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: camChecker.running = true
    }
}
