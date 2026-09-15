import QtQuick
import Quickshell

// Network bar module - opens NetworkPanel.qml's richer Wi-Fi/Ethernet
// flyout, a third option alongside the existing standalone
// NetworkToggle.qml/WifiToggle.qml icons (see NetworkPanel.qml's own
// header comment). Icon swaps between ethernet/wifi glyphs based on which
// is actually connected (ethernet takes priority when both are, matching
// how Linux itself generally prefers a wired route when one exists)
// rather than recoloring one fixed icon the way most other bar toggles
// do - there are genuinely two different connection *types* here, not
// just an on/off state of one.
Item {
    id: root

    property color textColor: "white"
    property color activeColor: "white"

    readonly property bool ethConnected: NetworkInterfacesService.ethernetDevices.some(function (d) { return d.state === "connected" })
    readonly property bool wifiConnected: NetworkInterfacesService.wifiDevices.some(function (d) { return d.state === "connected" })
    readonly property bool connected: root.ethConnected || root.wifiConnected

    implicitWidth: icon.implicitWidth
    implicitHeight: icon.implicitHeight

    NText {
        id: icon
        text: root.ethConnected ? "󰈀" : "󰖩"
        color: root.connected ? root.activeColor : root.textColor
        pointSize: Style.fontSizeL
    }

    MouseArea {
        anchors.fill: parent
        onClicked: {
            NetworkPanelState.anchorItem = root
            NetworkPanelState.activeTab = root.ethConnected ? "ethernet" : "wifi"
            NetworkPanelState.visible = !NetworkPanelState.visible
        }
    }
}
