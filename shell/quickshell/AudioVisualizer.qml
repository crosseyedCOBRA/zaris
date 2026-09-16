import QtQuick
import Quickshell
import Quickshell.Io

// Live audio level visualizer bar module - a small row of bars reacting
// to whatever's currently playing (the default sink's monitor, not the
// mic). A level meter, not a true frequency spectrum - see
// shell/zaris/audio-levels.sh's own header for why (RMS amplitude over
// small chunks via parec+python, not an FFT - simpler, and a real,
// working variant of what Noctalia's own "Audio Visualizer" widget
// offers, not a lesser substitute).
//
// Unlike every other bar module here, this one has real, continuous CPU
// cost (parec capturing audio forever) while it exists at all - but
// that's already handled correctly for free: BarStatusModules.qml's
// Loader only instantiates this component when ModulesConfig has it
// enabled, and destroys it (killing this Process along with it) the
// moment it's disabled - no extra visible-gating needed on top of that.
Item {
    id: root

    property color barColor: "white"
    property int barCount: 12
    property int barWidth: 3
    property int barSpacing: 2
    property int maxBarHeight: 16

    property var levels: []

    implicitWidth: root.barCount * root.barWidth + (root.barCount - 1) * root.barSpacing
    implicitHeight: root.maxBarHeight

    Process {
        id: capture
        running: true
        command: [Quickshell.env("HOME") + "/.config/zaris/audio-levels.sh"]
        stdout: SplitParser {
            onRead: data => {
                const level = parseFloat(data)
                if (isNaN(level))
                    return
                const next = root.levels.concat([level])
                if (next.length > root.barCount)
                    next.shift()
                root.levels = next
            }
        }
    }

    Row {
        anchors.verticalCenter: parent.verticalCenter
        spacing: root.barSpacing

        Repeater {
            model: root.barCount

            Rectangle {
                id: bar
                required property int index
                // Levels arrive oldest-first, newest last - bars read
                // left-to-right oldest-to-newest, so the newest sample is
                // always the rightmost bar (matches how a scrolling
                // waveform/level meter conventionally reads).
                readonly property real level: {
                    const i = bar.index - (root.barCount - root.levels.length)
                    return (i >= 0 && i < root.levels.length) ? root.levels[i] : 0
                }
                width: root.barWidth
                // sqrt compresses the RMS range so quiet-to-moderate
                // playback still produces visible movement, not just a
                // flat line until something's blasting at full volume -
                // real level meters (and this project's own volume
                // slider elsewhere) commonly apply similar compression
                // rather than a raw linear scale. Clamped to
                // maxBarHeight so a loud transient can't overflow the
                // module's own reserved layout space. A small minimum
                // height (2px) keeps every bar visibly present even at
                // near-silence, reading as "idle" rather than "broken/
                // invisible."
                height: Math.max(2, Math.min(root.maxBarHeight, Math.sqrt(bar.level) * root.maxBarHeight))
                anchors.bottom: parent.bottom
                radius: 1
                color: root.barColor

                // Was 80ms - noticeably smeared/laggy once audio-levels.sh
                // itself started reporting a fresh sample every 20ms
                // instead of every 50ms (see that script's own header for
                // the real fix, mostly --latency-msec) - a 80ms ease on
                // top of a 20ms sample rate meant several new samples
                // could arrive before the previous animation even
                // finished, reading as sluggish rather than responsive.
                // 40ms keeps a little smoothing (still nicer than a hard
                // instant snap) without visibly lagging behind the new
                // faster sample cadence.
                Behavior on height {
                    NumberAnimation { duration: 40 }
                }
            }
        }
    }
}
