import QtQuick
import Quickshell
import Quickshell.Io

// Network flyout: a Wi-Fi/Ethernet popup opened from a new "network" bar
// module, matching Noctalia v5's own reference (two screenshots supplied
// live - the Wi-Fi tab mid-scan, and the Ethernet tab with a connected
// interface and its own Info button) far more closely than the existing
// scattered NetworkToggle.qml/WifiToggle.qml bar icons do on their own -
// those two remain untouched and still work standalone, this is a third,
// additive option for anyone who wants the richer picker instead of (or
// alongside) plain toggle icons.
//
// PopupWindow anchored to the specific bar icon that opened it (same
// anchorItem-centering pattern NotificationHistoryPanel.qml already
// established, via BarConfig.popupAnchorY) rather than a centered
// FloatingWindow the way BluetoothPanel.qml is, or the whole-bar-surface
// anchor ControlCenter.qml uses (that one opens from a single fixed
// launcher, not a small icon among many others - see
// ControlCenterState.qml's own comment) - this is a bar-triggered
// quick-access flyout for one specific icon, not a standalone dialog.
//
// Wi-Fi tab: WifiNetworksService.qml's scanned network list, sorted
// strongest-first, one row per SSID (deduplicated across bands/BSSIDs -
// see that file's own comment). Tapping a known network (already has a
// saved NetworkManager profile) reconnects with no prompt; an unknown
// open network connects directly; an unknown secured network expands an
// inline password field in place, right in the row, rather than a
// separate dialog - kept in the same compact popup rather than spawning
// a second window for what's usually a one-time action per network.
//
// Ethernet tab: NetworkInterfacesService.qml's existing live device list
// (already built for Settings' own Network tab - reused as-is, not
// duplicated), filtered to ethernet-type devices, each row showing
// connection state and live rx/tx throughput. The Info button opens
// Settings' Network tab directly on that device (SettingsState's existing
// requestedCategory mechanism, the same one every other "jump to Settings"
// icon in this project already uses).
PopupWindow {
    id: root

    visible: NetworkPanelState.visible && !!NetworkPanelState.anchorItem
    color: Colors.bg

    implicitWidth: 360
    implicitHeight: contentColumn.implicitHeight + 32

    anchor.item: NetworkPanelState.anchorItem
    anchor.rect.x: NetworkPanelState.anchorItem ? (NetworkPanelState.anchorItem.width - implicitWidth) / 2 : 0
    anchor.rect.y: BarConfig.popupAnchorY(NetworkPanelState.anchorItem, implicitHeight)

    property bool wifiRadioEnabled: true

    Process {
        id: radioReader
        command: ["nmcli", "radio", "wifi"]
        stdout: StdioCollector {
            onStreamFinished: root.wifiRadioEnabled = this.text.trim() === "enabled"
        }
    }

    Timer {
        interval: 5000
        running: root.visible
        repeat: true
        triggeredOnStart: true
        onTriggered: radioReader.running = true
    }

    // Scan/refresh whenever the popup opens, not just on the service's
    // own 15s background timer - the same "don't make someone wait on a
    // stale list" reasoning most network pickers apply.
    onVisibleChanged: {
        if (root.visible) {
            radioReader.running = true
            WifiNetworksService.rescan()
        }
    }

    Rectangle {
        anchors.fill: parent
        color: Colors.bg
        border.width: 1
        border.color: Colors.pill

        Column {
            id: contentColumn
            anchors.top: parent.top
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.topMargin: 16
            width: parent.width - 32
            spacing: 12

            // --- header: icon + title + power toggle + settings + close ---
            Item {
                width: parent.width
                height: 32

                Row {
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 8

                    NIcon {
                        icon: NetworkPanelState.activeTab === "wifi" ? "󰤥" : "󰈀"
                        color: Colors.text
                        pointSize: Style.fontSizeL
                    }

                    NText {
                        text: NetworkPanelState.activeTab === "wifi" ? "Wi-Fi" : "Ethernet"
                        color: Colors.text
                        pointSize: Style.fontSizeM
                        font.weight: Style.fontWeightBold
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }

                Row {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 10

                    // Airplane Mode - relocated here from Control
                    // Center's quick-access row per explicit request
                    // ("instead of fully removing Airplane Mode, add
                    // that as a button to the top of the network widget
                    // in the bar") - a better fit grouped with this
                    // panel's own Wi-Fi radio toggle/Settings/Close than
                    // sitting redundantly next to individual Ethernet/
                    // Wifi toggles elsewhere. `nmcli networking off/on`
                    // (AirplaneModeState.qml) rather than this panel's
                    // own per-tab wifi-radio/ethernet-device controls -
                    // still the single "turn off everything at once"
                    // action, just living beside the controls for those
                    // same interfaces individually now.
                    Item {
                        id: airplaneModeButton
                        width: 26
                        height: 26

                        Rectangle {
                            anchors.fill: parent
                            radius: width / 2
                            color: airplaneModeArea.containsMouse ? Colors.pillActive : "transparent"
                            border.width: Style.borderS
                            border.color: Colors.textMuted
                            Behavior on color { ColorAnimation { duration: Style.animationFast } }
                        }

                        AirplaneMode {
                            anchors.centerIn: parent
                            clickable: false
                            textColor: Colors.textMuted
                            activeColor: Colors.red
                            pointSize: Style.fontSizeM
                        }

                        MouseArea {
                            id: airplaneModeArea
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: AirplaneModeState.toggle()
                            onEntered: TooltipService.show(airplaneModeButton, "Airplane Mode", "auto")
                            onExited: TooltipService.hide(airplaneModeButton)
                        }
                    }

                    ToggleSwitch {
                        visible: NetworkPanelState.activeTab === "wifi"
                        anchors.verticalCenter: parent.verticalCenter
                        checked: root.wifiRadioEnabled
                        onToggled: newChecked => {
                            Quickshell.execDetached(["nmcli", "radio", "wifi", newChecked ? "on" : "off"])
                            root.wifiRadioEnabled = newChecked
                        }
                    }

                    NIconButton {
                        baseSize: 26
                        icon: "󰒓"
                        tooltipText: "Settings"
                        onClicked: {
                            SettingsState.requestedCategory = "network"
                            SettingsState.requestedNetworkSubTab = NetworkPanelState.activeTab
                            SettingsState.targetItem = NetworkPanelState.anchorItem
                            NetworkPanelState.visible = false
                            SettingsState.visible = true
                        }
                    }

                    NIconButton {
                        baseSize: 26
                        icon: "󰅖"
                        tooltipText: "Close"
                        onClicked: NetworkPanelState.visible = false
                    }
                }
            }

            // --- tab switcher ---
            NTabBar {
                width: parent.width
                tabHeight: 30

                NTabButton {
                    text: "Wi-Fi"
                    pointSize: Style.fontSizeS
                    checked: NetworkPanelState.activeTab === "wifi"
                    onClicked: NetworkPanelState.activeTab = "wifi"
                }

                NTabButton {
                    text: "Ethernet"
                    pointSize: Style.fontSizeS
                    checked: NetworkPanelState.activeTab === "ethernet"
                    onClicked: NetworkPanelState.activeTab = "ethernet"
                }
            }

            // --- Wi-Fi tab content ---
            Column {
                width: parent.width
                spacing: 8
                visible: NetworkPanelState.activeTab === "wifi"

                Rectangle {
                    width: parent.width
                    radius: Style.radiusS
                    color: Colors.pill
                    height: Math.max(60, networksColumn.implicitHeight + 16)

                    NText {
                        visible: !root.wifiRadioEnabled
                        anchors.centerIn: parent
                        text: "Wi-Fi is off"
                        color: Colors.textMuted
                        pointSize: Style.fontSizeS
                    }

                    NBusyIndicator {
                        visible: root.wifiRadioEnabled && WifiNetworksService.scanning && WifiNetworksService.networks.length === 0
                        anchors.centerIn: parent
                        running: visible
                    }

                    NText {
                        visible: root.wifiRadioEnabled && WifiNetworksService.scanning && WifiNetworksService.networks.length === 0
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.top: parent.verticalCenter
                        anchors.topMargin: 28
                        text: "Searching for networks..."
                        color: Colors.textMuted
                        pointSize: Style.fontSizeXS
                    }

                    NText {
                        visible: root.wifiRadioEnabled && !WifiNetworksService.scanning && WifiNetworksService.networks.length === 0
                        anchors.centerIn: parent
                        text: "No networks found"
                        color: Colors.textMuted
                        pointSize: Style.fontSizeS
                    }

                    Column {
                        id: networksColumn
                        width: parent.width - 16
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.top: parent.top
                        anchors.topMargin: 8
                        spacing: 2
                        visible: root.wifiRadioEnabled && WifiNetworksService.networks.length > 0

                        Repeater {
                            model: WifiNetworksService.networks

                            Column {
                                id: netRow
                                required property var modelData
                                property bool expanded: false
                                width: parent.width

                                Rectangle {
                                    width: parent.width
                                    height: 40
                                    radius: Style.radiusS
                                    color: netRowArea.containsMouse ? Colors.pillActive : "transparent"

                                    Behavior on color { ColorAnimation { duration: Style.animationFast } }

                                    Row {
                                        anchors.left: parent.left
                                        anchors.verticalCenter: parent.verticalCenter
                                        anchors.leftMargin: 8
                                        spacing: 8

                                        NIcon {
                                            icon: netRow.modelData.signal >= 75 ? "󰤥" : netRow.modelData.signal >= 50 ? "󰤪" : netRow.modelData.signal >= 25 ? "󰤩" : "󰤨"
                                            color: netRow.modelData.inUse ? Colors.purple : Colors.textMuted
                                            pointSize: Style.fontSizeM
                                            anchors.verticalCenter: parent.verticalCenter
                                        }

                                        NIcon {
                                            visible: netRow.modelData.secured
                                            icon: "󰌾"
                                            color: Colors.textMuted
                                            pointSize: Style.fontSizeXS
                                            anchors.verticalCenter: parent.verticalCenter
                                        }

                                        NText {
                                            text: netRow.modelData.ssid
                                            color: Colors.text
                                            pointSize: Style.fontSizeS
                                            anchors.verticalCenter: parent.verticalCenter
                                        }
                                    }

                                    Row {
                                        anchors.right: parent.right
                                        anchors.verticalCenter: parent.verticalCenter
                                        anchors.rightMargin: 8
                                        spacing: 6

                                        NBusyIndicator {
                                            visible: WifiNetworksService.connectingSsid === netRow.modelData.ssid
                                            running: visible
                                            anchors.verticalCenter: parent.verticalCenter
                                            size: 16
                                        }

                                        NIcon {
                                            visible: netRow.modelData.inUse
                                            icon: "󰗠"
                                            color: Colors.purple
                                            pointSize: Style.fontSizeS
                                            anchors.verticalCenter: parent.verticalCenter
                                        }
                                    }

                                    MouseArea {
                                        id: netRowArea
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        enabled: !netRow.modelData.inUse && WifiNetworksService.connectingSsid === ""
                                        onClicked: {
                                            if (netRow.modelData.known || !netRow.modelData.secured) {
                                                WifiNetworksService.connect(netRow.modelData.ssid, netRow.modelData.known, "")
                                            } else {
                                                netRow.expanded = !netRow.expanded
                                            }
                                        }
                                    }
                                }

                                // --- inline password entry for an unknown
                                // secured network - expands in place rather
                                // than a separate dialog window, per the
                                // explicit decision to keep this a compact,
                                // one-popup flow.
                                Row {
                                    width: parent.width
                                    visible: netRow.expanded
                                    spacing: 6
                                    leftPadding: 8
                                    rightPadding: 8
                                    bottomPadding: 8

                                    NTextInput {
                                        id: pwField
                                        width: parent.width - connectBtn.width - parent.spacing - 16
                                        placeholderText: "Password"
                                        showClearButton: false
                                        // echoMode isn't one of NTextInput's own exposed
                                        // aliases - reaches the real inner TextField via
                                        // its own inputItem alias instead of adding a new
                                        // property to a shared component for one caller.
                                        Component.onCompleted: inputItem.echoMode = TextInput.Password
                                        onAccepted: {
                                            WifiNetworksService.connect(netRow.modelData.ssid, false, text)
                                            netRow.expanded = false
                                        }
                                    }

                                    NButton {
                                        id: connectBtn
                                        text: "Connect"
                                        fontSize: Style.fontSizeXS
                                        onClicked: {
                                            WifiNetworksService.connect(netRow.modelData.ssid, false, pwField.text)
                                            netRow.expanded = false
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                NText {
                    visible: WifiNetworksService.connectError !== ""
                    text: WifiNetworksService.connectError
                    color: Colors.red
                    pointSize: Style.fontSizeXS
                }
            }

            // --- Ethernet tab content ---
            Column {
                width: parent.width
                spacing: 8
                visible: NetworkPanelState.activeTab === "ethernet"

                NText {
                    text: "Available interfaces"
                    color: Colors.textMuted
                    pointSize: Style.fontSizeXS
                }

                NText {
                    visible: NetworkInterfacesService.ethernetDevices.length === 0
                    text: "No ethernet interfaces found"
                    color: Colors.textMuted
                    pointSize: Style.fontSizeS
                }

                Repeater {
                    model: NetworkInterfacesService.ethernetDevices

                    Rectangle {
                        id: ethRow
                        required property var modelData
                        width: parent.width
                        height: 52
                        radius: Style.radiusS
                        color: ethRow.modelData.state === "connected" ? Colors.pillActive : Colors.pill

                        Row {
                            anchors.left: parent.left
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.leftMargin: 10
                            spacing: 10

                            NIcon {
                                icon: "󰈀"
                                color: Colors.text
                                pointSize: Style.fontSizeL
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            Column {
                                spacing: 1
                                anchors.verticalCenter: parent.verticalCenter

                                NText {
                                    text: ethRow.modelData.device
                                    color: Colors.text
                                    pointSize: Style.fontSizeS
                                    font.weight: Style.fontWeightBold
                                }

                                NText {
                                    text: ethRow.modelData.state === "connected"
                                        ? ("Connected  \u2193 " + ethRow.modelData.rxKBs.toFixed(1) + "KB/s  \u2191 " + ethRow.modelData.txKBs.toFixed(1) + "KB/s")
                                        : "Disconnected"
                                    color: Colors.textMuted
                                    pointSize: Style.fontSizeXS
                                }
                            }
                        }

                        NIconButton {
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.rightMargin: 8
                            baseSize: 24
                            icon: "󰋽"
                            tooltipText: "Interface details"
                            onClicked: {
                                SettingsState.requestedCategory = "network"
                                SettingsState.requestedNetworkSubTab = "ethernet"
                                SettingsState.targetItem = NetworkPanelState.anchorItem
                                NetworkPanelState.visible = false
                                SettingsState.visible = true
                            }
                        }
                    }
                }
            }
        }
    }
}
