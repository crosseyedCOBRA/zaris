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
// ModulesConfig module at all - there's nothing to reorder it against,
// it's a variable-length list of whatever's actually running) stays
// pinned first in the "right" section. Volume and Control Center used to
// be hardcoded fixed positions here too (see this file's own git history)
// - both real modules now, with explicit default `order` values
// (99/100) reproducing the original hardcoded visual order (tray icons,
// then every module in moduleIds order, then volume, then Control
// Center) for anyone who's never touched the new Bar Modules tab.
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
                    case "ram": return ramComponent
                    case "network": return networkComponent
                    case "clipboard": return clipboardComponent
                    case "notifications": return notificationsComponent
                    case "wallpaper": return wallpaperComponent
                    case "battery": return batteryComponent
                    case "weather": return weatherComponent
                    case "brightness": return brightnessComponent
                    case "taskbar": return taskbarComponent
                    case "controlCenter": return controlCenterComponent
                    case "stayAwake": return stayAwakeComponent
                    case "nightLight": return nightLightComponent
                    case "dnd": return dndComponent
                    case "bluetooth": return bluetoothComponent
                    case "wifi": return wifiComponent
                    case "volume": return volumeComponent
                    default: return null
                    }
                }
            }
        }
    }

    Component {
        id: volumeComponent
        VolumeControl {
            textColor: Colors.purple
        }
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
        id: ramComponent
        MemUsage {
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
        id: weatherComponent
        WeatherIndicator {
            textColor: Colors.blue
        }
    }

    Component {
        id: brightnessComponent
        BrightnessIndicator {
            textColor: Colors.textMuted
        }
    }

    Component {
        id: taskbarComponent
        // Same component/wiring as the "taskbar" layoutMode's own embedded
        // strip (Bar.qml) - shared, not duplicated.
        DockIcons {
            iconSize: Math.max(20, Math.min(BarConfig.height - 12, 40))
            model: DockItemsService.dockItems
            onActivateRequested: DockItemsService.activate(windowId)
            onLaunchRequested: entry.execute()
            onReorderRequested: DockConfig.reorderPinned(appId, newIndex)
        }
    }

    Component {
        id: controlCenterComponent
        // BarControlCenterLauncher's root is an Image, whose own
        // implicitWidth/Height are read-only (follow the source's native
        // size, not the explicit 26x26 render size it sets) - same
        // wrapping-Item fix the launcher module needed above.
        Item {
            implicitWidth: 26
            implicitHeight: 26

            BarControlCenterLauncher {
                barPanel: root.barPanel
                barSurfaceItem: root.barSurfaceItem
            }
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
