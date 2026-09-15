import QtQuick
import Quickshell

// Desktop widget #2 (Clock was #1) - a media player card sitting directly
// on the wallpaper, always below every other window, matching Noctalia's
// own desktop widget family. Reuses MediaService.qml as-is (the same
// service Control Center's own media card already uses) rather than
// re-deriving anything - this is a second presentation of the same live
// data, not a second data source. Icon glyphs copied verbatim from
// ControlCenter.qml's own media card (same prev/play/pause/next PUA
// codepoints, already confirmed rendering correctly there) rather than
// picked fresh - see ROADMAP.md's own font-coverage-gap lesson from the
// RAM module for why reusing a proven glyph beats guessing a new one.
//
// windowrule=float + alwaysbottom + bottomleft,title:^DesktopMedia$ in
// zaris.conf - "bottomleft" is new, WM-side (mirror of "topleft", see
// windowManager - Clock already has the top-left corner).
//
// Only visible while something's actually playing (MediaService.
// currentPlayer), same as Control Center's own card - an empty "nothing
// playing" card sitting permanently on the desktop would be visual noise,
// not a widget.
FloatingWindow {
    id: root

    visible: DesktopWidgetsConfig.isEnabled("media") && !!MediaService.currentPlayer
    title: "DesktopMedia"
    color: "transparent"

    implicitWidth: 280
    implicitHeight: 150

    Rectangle {
        anchors.fill: parent
        radius: Style.radiusM
        color: Colors.bg
        border.width: 1
        border.color: Colors.pill
        clip: true

        Image {
            anchors.fill: parent
            source: MediaService.trackArtUrl
            visible: MediaService.trackArtUrl !== ""
            fillMode: Image.PreserveAspectCrop
        }

        Rectangle {
            anchors.fill: parent
            gradient: Gradient {
                GradientStop { position: 0.0; color: Qt.rgba(0, 0, 0, 0.1) }
                GradientStop { position: 1.0; color: Qt.rgba(0, 0, 0, 0.8) }
            }
        }

        Column {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.margins: 10
            spacing: 6

            Column {
                width: parent.width
                spacing: 1

                NText {
                    text: MediaService.trackTitle
                    width: parent.width
                    elide: Text.ElideRight
                    color: Colors.text
                    pointSize: Style.fontSizeM
                    font.weight: Style.fontWeightBold
                }

                NText {
                    text: MediaService.trackArtist
                    width: parent.width
                    elide: Text.ElideRight
                    color: Colors.coral
                    pointSize: Style.fontSizeS
                }
            }

            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 14

                NIconButton {
                    baseSize: 24
                    icon: ""
                    enabled: MediaService.canGoPrevious
                    onClicked: MediaService.previous()
                }

                NIconButton {
                    baseSize: 30
                    icon: MediaService.isPlaying ? "" : ""
                    onClicked: MediaService.playPause()
                }

                NIconButton {
                    baseSize: 24
                    icon: ""
                    enabled: MediaService.canGoNext
                    onClicked: MediaService.next()
                }
            }
        }
    }
}
