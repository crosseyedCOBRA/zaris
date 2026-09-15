pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Desktop widget config (Clock/Weather/Media/SystemStats - see ROADMAP.md's
// Noctalia desktop-widgets entry), backed by
// ~/.config/quickshell/desktopwidgets.json. Same pattern as
// ModulesConfig.qml/modules.json and DockConfig.qml/dock.json: hand-editable
// directly, or through Settings.qml's "Desktop Widgets" category - both take
// effect live, no qs restart needed. A plain per-id "enabled" map rather
// than ModulesConfig's fuller shape (screens/tray/section/order) - none of
// those bar-specific concepts apply here, desktop widgets aren't per-monitor
// or bar-embedded.
QtObject {
    id: root

    readonly property var widgetIds: ["clock", "media", "systemStats"]

    property FileView configFile: FileView {
        path: Quickshell.env("HOME") + "/.config/quickshell/desktopwidgets.json"
        watchChanges: true
        onFileChanged: reload()
        onAdapterUpdated: writeAdapter()

        adapter: JsonAdapter {
            property var enabled: ({ "clock": true })
        }
    }

    function isEnabled(id) {
        const e = configFile.adapter.enabled
        return e && e[id] !== undefined ? !!e[id] : true
    }

    function setEnabled(id, val) {
        const e = Object.assign({}, configFile.adapter.enabled)
        e[id] = val
        configFile.adapter.enabled = e
    }
}
