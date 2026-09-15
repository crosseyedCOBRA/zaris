import QtQuick
import Quickshell
import Quickshell.Io

// Screen color picker bar module - click the icon, click anywhere on
// screen, the sampled hex color is copied to the clipboard and confirmed
// via a notification. Wraps xcolor (a real, purpose-built X11 color
// picker CLI, not hand-rolled from raw X11 primitives) the same way
// screenshot.sh wraps maim/slop - a thin shell-out, not a reimplementation.
// `-s clipboard` does the copy itself; the stdout capture here is purely
// so the notification can show which color actually got copied.
Item {
    id: root

    property color textColor: "white"
    property string lastColor: ""

    implicitWidth: icon.implicitWidth
    implicitHeight: icon.implicitHeight

    NText {
        id: icon
        text: "" // nf-fa-tint
        color: root.textColor
        pointSize: Style.fontSizeL
    }

    Process {
        id: picker
        command: ["xcolor", "-s", "clipboard"]
        stdout: StdioCollector {
            onStreamFinished: {
                const hex = this.text.trim()
                if (hex.length === 0)
                    return
                root.lastColor = hex
                Quickshell.execDetached(["notify-send", "Color picked", hex + " copied to clipboard"])
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        onClicked: picker.running = true
    }
}
