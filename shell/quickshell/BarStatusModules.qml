import QtQuick

// One of the bar's three module zones (Left/Center/Right), rendering
// whichever modules Settings' new "Bar Modules" tab has assigned to
// `section` in their configured order (ModulesConfig.orderedBarModules) -
// previously this was one single hardcoded Row of every status module,
// always in the same fixed order, always on the right. See Bar.qml's own
// comment for why the "taskbar" layout mode ignores section assignment
// entirely (its left/center are already spoken for by the embedded
// dock/workspaces) via `anySection: true` instead.
//
// SystemTrayRow (the real X11/StatusNotifierItem system tray, not a
// ModulesConfig module at all) and VolumeControl (deliberately excluded
// from ModulesConfig gating - see its own header comment) both stay
// pinned to fixed positions within the "right" section specifically
// (SystemTrayRow first, VolumeControl last) rather than becoming
// reorderable/movable modules themselves - this exactly reproduces the
// original hardcoded layout's default visual order (tray icons, then
// every module in moduleIds order, then volume, then Control Center)
// for anyone who's never touched the new Bar Modules tab, since every
// module defaults to section "right" with moduleIds order preserved.
//
// Each module id maps to a specific, differently-propped component below
// (icon glyphs, sensor labels, text/active colors) - a Repeater +
// per-delegate Loader picks the right one by id by only enabling the one
// `Component` whose `active` matches, rather than trying to force every
// module into one generic shape.
Row {
    id: root

    required property var barPanel
    required property Item barSurfaceItem
    required property string section
    // "taskbar" layout mode only - see this file's own header comment.
    property bool anySection: false

    spacing: 14

    SystemTrayRow {
        window: root.barPanel
        visible: root.section === "right" && root.barPanel.isPrimary
        anchors.verticalCenter: parent.verticalCenter
    }

    Repeater {
        model: root.anySection
            ? ModulesConfig.orderedBarModulesAnySection(root.barPanel)
            : ModulesConfig.orderedBarModules(root.section, root.barPanel)

        Item {
            id: delegateItem
            required property string modelData
            width: loader.item ? loader.item.implicitWidth : 0
            height: loader.item ? loader.item.implicitHeight : 0

            Loader {
                id: loader
                anchors.verticalCenter: parent.verticalCenter
                sourceComponent: {
                    switch (delegateItem.modelData) {
                    case "launcher": return launcherComponent
                    case "workspaces": return workspacesComponent
                    case "kernel": return kernelComponent
                    case "cpu": return cpuComponent
                    case "cpuTemp": return cpuTempComponent
                    case "gpuTemp": return gpuTempComponent
                    case "network": return networkComponent
                    case "clipboard": return clipboardComponent
                    case "notifications": return notificationsComponent
                    case "wallpaper": return wallpaperComponent
                    case "battery": return batteryComponent
                    case "stayAwake": return stayAwakeComponent
                    case "nightLight": return nightLightComponent
                    case "dnd": return dndComponent
                    case "bluetooth": return bluetoothComponent
                    case "wifi": return wifiComponent
                    default: return null
                    }
                }
            }
        }
    }

    VolumeControl {
        // Deliberately not gated by ModulesConfig.showInBar
        // ("volume", ...) - see VolumeControl.qml's own header comment.
        // Falls back to its own internal `visible: sink && sink.ready`
        // binding.
        visible: root.section === "right"
        textColor: Colors.purple
        anchors.verticalCenter: parent.verticalCenter
    }

    Component {
        id: launcherComponent
        Item {
            // Image's own implicitWidth/Height are read-only (follow the
            // source's native pixel size, not the explicit render size
            // below) - wrapped in a plain Item so the delegate's own
            // width/height (bound to loader.item.implicitWidth/Height)
            // gets the real 22x22 render size instead.
            implicitWidth: 22
            implicitHeight: 22

            Image {
                anchors.fill: parent
                source: "file://" + BarConfig.launcherIcon
                // Downscales a large custom user image at load time
                // instead of letting the GPU minify it at render time
                // (pixelated) - see Bar.qml's own former copy of this
                // Image for the fuller explanation.
                sourceSize.width: 44
                sourceSize.height: 44
            }

            MouseArea {
                anchors.fill: parent
                onClicked: LauncherState.visible = !LauncherState.visible
            }
        }
    }

    Component {
        id: workspacesComponent
        Workspaces {}
    }

    Component {
        id: kernelComponent
        KernelVersion {
            textColor: Colors.blue
        }
    }

    Component {
        id: cpuComponent
        CpuLoad {
            textColor: Colors.coral
        }
    }

    Component {
        id: cpuTempComponent
        HwmonSensor {
            sensorLabel: "Tctl" // k10temp CPU die sensor -- verify with
                                 // `grep . /sys/class/hwmon/hwmon*/temp*_label`
                                 // and adjust if different
            iconGlyph: ""
            textColor: Colors.blue
        }
    }

    Component {
        id: gpuTempComponent
        HwmonSensor {
            sensorLabel: "edge" // amdgpu GPU sensor -- same caveat as above
            iconGlyph: ""
            textColor: Colors.teal
        }
    }

    Component {
        id: networkComponent
        NetworkStatus {
            textColor: Colors.blue
            barSurfaceItem: root.barSurfaceItem
        }
    }

    Component {
        id: clipboardComponent
        ClipboardIndicator {
            textColor: Colors.textMuted
            activeColor: Colors.blue
        }
    }

    Component {
        id: notificationsComponent
        NotificationIndicator {
            textColor: Colors.textMuted
            activeColor: Colors.purple
        }
    }

    Component {
        id: wallpaperComponent
        WallpaperIndicator {
            textColor: Colors.textMuted
            activeColor: Colors.teal
        }
    }

    Component {
        id: batteryComponent
        BatteryIndicator {
            visible: BatteryService.batteryPresent
            textColor: Colors.textMuted
        }
    }

    Component {
        id: stayAwakeComponent
        StayAwake {
            textColor: Colors.textMuted
            activeColor: Colors.coral
        }
    }

    Component {
        id: nightLightComponent
        NightLight {
            textColor: Colors.textMuted
            activeColor: Colors.blue
        }
    }

    Component {
        id: dndComponent
        Dnd {
            textColor: Colors.textMuted
            activeColor: Colors.red
        }
    }

    Component {
        id: bluetoothComponent
        BluetoothIndicator {
            textColor: Colors.textMuted
            activeColor: Colors.blue
        }
    }

    Component {
        id: wifiComponent
        WifiToggle {
            textColor: Colors.textMuted
            activeColor: Colors.blue
            settingsShortcut: true
            barSurfaceItem: root.barSurfaceItem
        }
    }
}
