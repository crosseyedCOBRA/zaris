import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Services.Pipewire

// Phase 3 of the Noctalia-port effort (see ROADMAP.md): the old flat
// "hidden overflow" flyout, rebuilt as a single-column Control Center - header actions,
// quick-toggle grid, quick-launch actions, volume, kernel/network status,
// then a media card paired with a small cluster of circular system-stat
// gauges (CPU load, CPU/GPU temp, battery). Not a port of Noctalia v5's own
// Control Center (its code is Wayland/OpenGL-native, nothing to port),
// just the same idea built from Zaris's existing services: a richer, more
// scannable landing spot than one long column of label+widget rows.
// Deliberately skipped one piece of Noctalia's version that has no Zaris
// equivalent yet: weather+power-profile (no weather service or
// power-profile switching exists here - weather specifically is next up,
// per the user, not folded into this pass).
//
// Eighth pass: added the profile header (avatar, display name, uptime)
// this file's own comment used to list as intentionally skipped - "the
// bar's own clock is already visible behind this panel" reasoning applied
// to the clock specifically, not the profile block as a whole, and the
// user asked for the full header once the rest of the panel was in place.
// `HostService.qml` already had `displayName`/`username` from Phase 1
// (ported but never given a real use site until now) - only `uptimeText`
// is new there. No real `~/.face` exists on this machine, so the avatar
// falls back to a single-letter badge (`DockIcons.qml`'s existing
// fallback-avatar pattern, reused verbatim: `Colors.pill` circle + bold
// first-letter `NText`) - real-photo support (a `MultiEffect` circular
// mask, since Qt Quick's `Image` can't clip to a non-rectangular shape on
// its own) was verified separately with a throwaway test file, not left
// unverified just because this machine has nothing to show through it.
//
// Seventh pass: the media card is now a real "now playing" card (album art
// as a full-bleed background behind title/artist/album, a real seek
// scrubber via MediaService.seekByRatio(), bigger playback buttons) rather
// than a small thumbnail+text row, matching Noctalia's reference Control
// Center screenshot (not just its bar, which is all earlier passes had to
// go on). The old single master-volume row is now a real audio section -
// separate Output and Input columns, each with its own mute button,
// elided device `description` (Quickshell's Pipewire `PwNode`, confirmed
// via its qmltypes - `name`/`description`/`nickname` all exist, `description`
// reads closest to Noctalia's own verbose device names), and volume
// slider - `Pipewire.defaultAudioSource` (the input/mic device) is newly
// tracked alongside the existing `defaultAudioSink`.
//
// Third pass: dropped the Home/System tab split from the second pass -
// the user asked for the "System" section folded back into the main view
// after seeing Noctalia's own reference screenshot has no tabs at all,
// just one continuous column. Kernel/Network moved up into the main flow
// as plain rows; CPU load, CPU temp, GPU temp, and Battery became
// NCircularGauge dials (matching the small circular readouts clustered
// next to Noctalia's own media card) instead of separate label+row lines.
//
// Second pass: Settings, the power menu, and a close button moved here
// from being bare always-visible Bar.qml icons (a fixed header, visible
// at the top of the column); Clipboard, Wallpaper, and Screenshot got a
// quick-launch icon row (opening the same existing panels/script their old
// bar icons did). Clipboard/Wallpaper/Battery/Dnd's `modules.json`
// `inControlCenter` (named `tray` at the time) default flipped to `true`
// at the same time (ModulesConfig.qml), so they stop appearing inline in
// the bar automatically - no Bar.qml changes needed for those four, the
// existing showInControlCenter() mechanism already covers it.
//
// Same "inControlCenter": true opt-in from modules.json still gates
// every module here, exactly as its predecessor did in the old flat
// Overflow.qml - this is a presentation change, not a new config
// surface. Live state (StayAwake, NightLight, Dnd,
// Bluetooth, volume, media) is read from the same shared singletons/
// services the bar's inline modules use, so toggling from here stays in
// sync with the bar.
// Built on PopupWindow rather than a FloatingWindow, same reasoning as
// Settings.qml/CalendarFlyout.qml: anchors directly to the bar's own
// full-width background surface (ControlCenterState.barItem, set by
// whichever monitor's launcher icon was actually clicked) via `anchor.item`
// rather than a WM-side `topright 14 48` windowrule fixed to one screen
// corner - the WM rule looked fine while the bar only ever lived at the
// top, but once BarConfig.position could also be "bottom" (see BarConfig's
// own comment), a fixed top-right corner would leave Control Center
// visually disconnected from a bar that's actually at the bottom of the
// screen. Right-aligned under the bar (anchor.rect.x) and opening
// above/below it depending on BarConfig.position (BarConfig.popupAnchorY,
// shared with every other bar-anchored popup) keeps it attached to the bar
// wherever the bar actually is.
PopupWindow {
    id: root

    visible: ControlCenterState.visible && !!ControlCenterState.barItem
    color: Colors.bg

    // Fixed size, same reasoning as Settings.qml's fixed 680x460 - a real
    // bug found while building the second pass (not just a Xephyr-sandbox
    // artifact, confirmed via a debug Timer on the LIVE desktop with a
    // real WM running): FloatingWindow's actual OS-level height never
    // tracked content.implicitHeight growing after first map (this window
    // was a FloatingWindow at the time; PopupWindow has never been
    // observed to have this problem, but the fixed size is kept regardless
    // since nothing about this panel's content actually needs to grow).
    // Sidestepped the same way Settings.qml already does for its own
    // differently-sized categories - one fixed size generous enough for
    // the tallest state this panel can be in (every optional row/dial
    // visible at once). Widened a bit and given real side padding (the
    // content column stays at its existing contentWidth, just with more
    // breathing room on either side of it now) plus a subtle outer border
    // - a cleaner match for Noctalia's own reference screenshot, which has
    // visible padding and a bit of background definition around its
    // Control Center rather than content running edge-to-edge.
    // Was 440 - widened a bit per explicit request ("a bit wider"),
    // extra room going into this panel's own outer side padding rather
    // than contentWidth (below) so the fixed-width media/gauges cards
    // don't end up with a stretched, oddly wide gap between them.
    implicitWidth: 460
    // Was 875 (tuned for the old toggle grid's large labeled 2-column
    // tiles - see that section's own history for why it needed that much).
    // Recalibrated down to 660 once the toggle grid became two compact
    // icon-only pill rows (freed roughly 200px on its own) even after
    // adding back a previously-broken audio section and a new visualizer
    // row - reported live as a large, obviously dead gap at the panel's
    // own bottom edge below the last real content (confirmed via direct
    // pixel sampling down the panel's background: real content ended
    // around 560px into the panel, nearly 300px short of the old fixed
    // 875). 660 left a real, deliberate margin above that measured
    // content height instead of matching it exactly - still "fixed, sized
    // generously for the tallest real state" per this property's own
    // long-standing reasoning above, just recalibrated for the new
    // layout rather than carrying the old one's number forward
    // unexamined.
    //
    // Bumped up again to 740 - the four new offset-background cards
    // added since (profile header, the quick-access button row, Now
    // Playing, the gauges) each added their own +24px of padding on top
    // of the content they wrap, growing this panel's real total content
    // height meaningfully beyond what 660 was tuned for - reported live
    // as needing "a bit taller." Same "generous fixed size, no scrolling"
    // reasoning as before, not a return to the old 875 (nothing here
    // needs nearly that much).
    implicitHeight: 740

    anchor.item: ControlCenterState.barItem
    anchor.rect.x: ControlCenterState.barItem ? ControlCenterState.barItem.width - implicitWidth : 0
    anchor.rect.y: BarConfig.popupAnchorY(ControlCenterState.barItem, implicitHeight)

    readonly property PwNode pwSink: Pipewire.defaultAudioSink
    readonly property PwNode pwSource: Pipewire.defaultAudioSource
    PwObjectTracker {
        objects: (root.pwSink ? [root.pwSink] : []).concat(root.pwSource ? [root.pwSource] : [])
    }

    // Same "primary monitor represents them all" reasoning OSD.qml's own
    // showPrimaryBrightness() already established - BrightnessService.
    // setBrightness()/increaseBrightness()/decreaseBrightness() already
    // apply to every monitor at once, so one slider reading/driving the
    // primary monitor's value stays consistent with what the OSD popup
    // (and the XF86MonBrightness keybinds behind it) already show.
    readonly property var primaryBrightnessMonitor: BrightnessService.getMonitorForScreen(Quickshell.screens[0])

    readonly property int labelWidth: 80
    readonly property int contentWidth: 380
    readonly property int tileWidth: 150
    // Was 64 - trimmed to reclaim the ~40px the 5-day forecast row below
    // (WeatherWidget's icon+temp lines, not just its day-label line) needs
    // to actually fit inside this panel's own fixed 830px height without
    // clipping - confirmed live via a taller-than-needed Xephyr test screen
    // that the clipping was this panel's own fixed height budget, not
    // screen size, so reclaiming space here (5 toggle-grid rows × 8px) was
    // the fix rather than growing implicitHeight, which the comment on
    // that property explicitly warns against reintroducing (a taller fixed
    // panel risked needing the scrolling behavior Control Center is
    // deliberately never supposed to have).
    readonly property int tileHeight: 56

    // Hidden property sources for the CPU/temp gauges below - reuse
    // CpuLoad.qml/HwmonSensor.qml's own already-proven live-polling logic
    // (Process/Timer) rather than re-deriving /proc/stat or hwmon parsing,
    // just without their own built-in icon+text Row (NCircularGauge draws
    // its own). Timers keep running regardless of visible: false - only
    // their own internal Row rendering is suppressed.
    CpuLoad {
        id: cpuSource
        visible: false
    }

    HwmonSensor {
        id: cpuTempSource
        sensorLabel: "Tctl"
        iconGlyph: ""
        visible: false
    }

    HwmonSensor {
        id: gpuTempSource
        sensorLabel: "edge"
        iconGlyph: ""
        visible: false
    }

    MemUsage {
        id: memSource
        visible: false
    }

    Rectangle {
        anchors.fill: parent
        color: Colors.bg
        // 10, matching zaris.conf's own `rounding=10` - per explicit
        // request to have this panel's own rounding match the config
        // file's value rather than the smaller Style.radiusS its inner
        // cards use.
        radius: 10
        border.width: 1
        // ThemeConfig.borderAccent - the same active-border accent color
        // the WM itself applies to focused window borders (col.
        // active_border in zaris.conf, kept in sync with this by
        // ThemeConfig's own regex-backed setter) - was Colors.pill (a
        // neutral surface tone, not really a border accent at all) per
        // explicit request to have this border "match the color palette
        // in use."
        border.color: ThemeConfig.borderAccent

        Column {
            id: content
            anchors.top: parent.top
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.topMargin: 8
            // Was 8 - bumped once every remaining bare row got its own
            // offset-background card (the status card, the weather card,
            // the media card, the toggle-pill row), so sections read as
            // genuinely separate blocks instead of sitting flush against
            // each other - per explicit request ("a little padding
            // between sections so they don't look so on top of each
            // other").
            spacing: 14

            // Profile header - its own offset-background card now,
            // matching every other section below (status/audio, the
            // quick-access buttons, weather, media, gauges) instead of
            // being the one remaining bare row sitting directly on the
            // panel's own background - per explicit request to give this
            // section the same treatment.
            Rectangle {
                width: root.contentWidth
                height: 44 + 24
                radius: Style.radiusS
                color: Colors.pill

                Item {
                    anchors.centerIn: parent
                    width: parent.width - 24
                    height: 44

                    Row {
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 10

                        Item {
                            id: avatar
                        width: 44
                        height: 44
                        anchors.verticalCenter: parent.verticalCenter

                        Image {
                            id: faceImage
                            // Purely a display now - clicking this avatar
                            // used to open AvatarPickerPanel.qml directly;
                            // picture changing is a Settings-only affordance
                            // now (Profile tab), per explicit request. The
                            // `?v=` query string does nothing to which file
                            // actually loads (file:// URLs ignore query
                            // strings) - it's purely there so
                            // AvatarPickerPanelState.setAvatar() bumping
                            // AvatarPickerPanelState.version after
                            // overwriting ~/.face in place (whether that
                            // came from AvatarPickerPanel.qml's own grid or
                            // Settings' typed-path field, both now go
                            // through the same shared setAvatar()) forces
                            // QML's image cache (keyed on the full URL
                            // string, not the file's actual contents) to
                            // treat it as a different image and reload,
                            // rather than keep showing whatever it cached
                            // before.
                            source: "file://" + Quickshell.env("HOME") + "/.face?v=" + AvatarPickerPanelState.version
                            asynchronous: true
                            fillMode: Image.PreserveAspectCrop
                            width: avatar.width
                            height: avatar.height
                            visible: false
                            layer.enabled: true
                        }

                        Rectangle {
                            id: avatarMask
                            width: avatar.width
                            height: avatar.height
                            radius: width / 2
                            visible: false
                            layer.enabled: true
                        }

                        MultiEffect {
                            anchors.fill: parent
                            source: faceImage
                            maskEnabled: true
                            maskSource: avatarMask
                            visible: faceImage.status === Image.Ready
                        }

                        // Fallback logo - the asset itself is a square PNG
                        // (an opaque black square with the circular logo
                        // mark drawn in the middle, not a transparent-
                        // cornered circle), so it needs the exact same
                        // circular mask as the real-photo path above rather
                        // than rendering unmasked - reported live as "the
                        // profile picture looks like an odd square" (the
                        // asset's own square corners showing through
                        // whenever no real ~/.face exists, the actual
                        // default state on a fresh install).
                        Image {
                            id: fallbackLogo
                            source: "file://" + Quickshell.env("HOME") + "/.config/quickshell/assets/zaris-logo-circle.png"
                            width: avatar.width
                            height: avatar.height
                            visible: false
                            fillMode: Image.PreserveAspectCrop
                            layer.enabled: true
                        }

                        MultiEffect {
                            anchors.fill: parent
                            source: fallbackLogo
                            maskEnabled: true
                            maskSource: avatarMask
                            visible: faceImage.status !== Image.Ready
                        }
                    }

                    Column {
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 1

                        NText {
                            text: HostService.displayName
                            color: Colors.text
                            pointSize: Style.fontSizeM
                            font.weight: Style.fontWeightBold
                        }

                        NText {
                            text: "Uptime: " + HostService.uptimeText
                            visible: HostService.uptimeText !== ""
                            color: Colors.textMuted
                            pointSize: Style.fontSizeXS
                        }
                    }
                }

                Row {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 6

                    NIconButton {
                        baseSize: 26
                        icon: ""
                        tooltipText: "Settings"
                        // Reported live as still visibly off-center after
                        // the sound-output icon's own fix (see
                        // NIconButton.qml's iconOffsetX comment) - this
                        // session's own earlier sandbox measurement read
                        // this glyph (U+F013) as close to centered, but
                        // that measurement was taken under this machine's
                        // Xephyr/llvmpipe software-GL sandbox, not
                        // necessarily identical to how the real GPU-
                        // accelerated live desktop actually hints/
                        // rasterizes it - trusting the live, direct report
                        // over the sandbox measurement here. First attempt
                        // (-3) overshot per a same-day live follow-up -
                        // "come back to the right a really small amount,
                        // probably 1-2px" - landed at -1.5, then one more
                        // half-pixel left per a further live follow-up.
                        iconOffsetX: -2
                        // Settings now opens as a PopupWindow anchored to
                        // the bar's own full-width surface
                        // (ControlCenterState.barItem, set by Bar.qml
                        // whenever the launcher icon is clicked) rather
                        // than a centered FloatingWindow - not this
                        // button itself, since Control Center closes at
                        // the same time Settings opens, and a
                        // PopupWindow can't anchor to a target inside a
                        // window that's just been hidden (confirmed by
                        // testing: anchoring here directly never showed
                        // anything, regardless of statement order).
                        onClicked: {
                            // Always General specifically, regardless of
                            // whichever tab Settings was last left open on -
                            // per explicit request, this gear is the one
                            // "just open Settings" entry point, distinct
                            // from the other Control Center icons that
                            // jump to their own specific tab (Ethernet,
                            // Wifi, Battery, etc.) via this same
                            // requestedCategory mechanism (see
                            // AudioMixerPanel.qml's own gear button for the
                            // first user of it).
                            SettingsState.requestedCategory = "general"
                            SettingsState.targetItem = ControlCenterState.barItem
                            // Close Control Center *before* opening Settings,
                            // not after - both are override-redirect
                            // Quickshell popups the WM continuously re-raises
                            // (windowManager.cpp's alwaysOnTopWindows/
                            // reassertAlwaysOnTop), so briefly having both
                            // visible at once (the previous order) left a
                            // real, if narrow, window for that raise logic to
                            // race with Settings' own first paint - reported
                            // live as Settings flashing open then
                            // disappearing, with a second click doing
                            // nothing (SettingsState.visible was already
                            // true, so setting it to the same value again is
                            // a no-op - see Settings.qml's own onClosed
                            // handler for the other half of this fix).
                            ControlCenterState.visible = false
                            SettingsState.visible = true
                        }
                    }

                    NIconButton {
                        baseSize: 26
                        icon: ""
                        tooltipText: "Power menu"
                        // Same live report as the Settings gear just above - see
                        // its own comment for why this is trusted over this
                        // session's earlier sandbox measurement.
                        iconOffsetX: -2
                        onClicked: {
                            PowerMenuPanelState.visible = true
                            ControlCenterState.visible = false
                        }
                    }

                    NIconButton {
                        baseSize: 26
                        icon: ""
                        tooltipText: "Close"
                        onClicked: ControlCenterState.visible = false
                    }
                }
            }
            }

            // Running kernel version - its own small, always-visible
            // section (not gated by ModulesConfig's enable/inControlCenter system the
            // way the bar's own copy of this module is) since the kernel
            // module's bar default flipped to disabled - the user still
            // wanted it visible somewhere by default, just not taking up
            // bar space. A second, independent KernelVersion instance
            // (its own one-shot `uname -r` Process) rather than sharing
            // the bar's - the same "duplicate the self-contained module
            // rather than share the bar's own instance" approach this file
            // already uses for cpuSource/cpuTempSource/gpuTempSource above.
            // textColor is Colors.text (this panel's own neutral text
            // color), not the bar's accent-colored textColor prop, so it
            // reads as regular themed Control Center text and follows a
            // palette change like everything else here.
            // Combined "status" card - Running Kernel, the audio
            // Output/Input sliders, and the brightness slider, all in one
            // shared offset-background block instead of three separate
            // bare rows sitting directly on the panel's own background -
            // per explicit request ("each section should have an
            // off-setting background... so they don't look so on top of
            // each other"), matching the same Colors.pill treatment the
            // toggle pills/media card already use elsewhere in this file.
            // Each row keeps its own independent visible: binding
            // (audio/brightness both already had one; Kernel is
            // unconditional) - the Column below reflows automatically
            // when one collapses, and this Rectangle's own height follows
            // that reflow via statusColumn.implicitHeight, so a missing
            // audio device or non-DDC monitor doesn't leave dead padding
            // behind.
            Rectangle {
                width: root.contentWidth
                height: statusColumn.implicitHeight + 24
                radius: Style.radiusS
                color: Colors.pill

                Column {
                    id: statusColumn
                    anchors.centerIn: parent
                    width: parent.width - 24
                    spacing: 10

            Row {
                width: parent.width
                spacing: 8

                NText {
                    text: "Running Kernel"
                    color: Colors.textMuted
                    pointSize: Style.fontSizeXS
                    anchors.verticalCenter: parent.verticalCenter
                }

                KernelVersion {
                    textColor: Colors.text
                    anchors.verticalCenter: parent.verticalCenter
                }
            }

            // Real bug fixed here, found comparing against Noctalia's own
            // reference Control Center (which always shows full Output/
            // Input device sliders, alongside a separate, independent
            // compact volume icon in its own bar): this row used to also
            // require ModulesConfig.showInControlCenter("volume", ...), tying it to
            // whether the *bar's* own volume icon was configured as a
            // Control-Center-shown module - "volume"'s own default is a bar icon
            // (inControlCenter: false, see ModulesConfig.qml), so on an unmodified
            // install this whole audio section silently never rendered at
            // all, regardless of whether real, ready sink/source devices
            // existed. Audio control belongs in Control Center as its own
            // first-class section, not gated behind a setting that governs
            // a completely different location's icon - removed the
            // showInControlCenter("volume") condition, leaving only the real
            // "do I have anything to show" check.
            Row {
                width: parent.width
                spacing: 14
                visible: (!!root.pwSink && root.pwSink.ready) || (!!root.pwSource && root.pwSource.ready)

                Column {
                    width: (parent.width - parent.spacing) / 2
                    spacing: 4
                    visible: !!root.pwSink && root.pwSink.ready

                    Row {
                        width: parent.width
                        spacing: 6

                        NIconButton {
                            readonly property bool muted: root.pwSink && root.pwSink.ready && root.pwSink.audio.muted
                            baseSize: 22
                            icon: muted ? "󰖁" : ""
                            // U+F028's own real ink sits measurably right of
                            // its character cell's center (confirmed via a
                            // dedicated Xephyr test harness, see
                            // NIconButton.qml's iconOffsetX comment) -
                            // reported live as this "sound output" icon
                            // looking off-center. Scoped to the unmuted
                            // glyph specifically, the one actually measured;
                            // the muted glyph (a different codepoint,
                            // U+F0581) wasn't verified to have the same
                            // issue, so it's left at 0 rather than guessed.
                            iconOffsetX: muted ? 0 : -5
                            anchors.verticalCenter: parent.verticalCenter
                            onClicked: {
                                if (root.pwSink)
                                    root.pwSink.audio.muted = !root.pwSink.audio.muted
                            }
                        }

                        NText {
                            text: root.pwSink && root.pwSink.ready ? root.pwSink.description : ""
                            width: parent.width - 22 - parent.spacing
                            elide: Text.ElideRight
                            color: Colors.textMuted
                            pointSize: Style.fontSizeXS
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }

                    NSlider {
                        width: parent.width
                        from: 0
                        to: 1.0
                        value: root.pwSink && root.pwSink.ready ? root.pwSink.audio.volume : 0
                        onMoved: {
                            if (root.pwSink)
                                root.pwSink.audio.volume = value
                        }
                    }
                }

                Column {
                    width: (parent.width - parent.spacing) / 2
                    spacing: 4
                    visible: !!root.pwSource && root.pwSource.ready

                    Row {
                        width: parent.width
                        spacing: 6

                        NIconButton {
                            baseSize: 22
                            icon: (root.pwSource && root.pwSource.ready && root.pwSource.audio.muted) ? "" : ""
                            anchors.verticalCenter: parent.verticalCenter
                            onClicked: {
                                if (root.pwSource)
                                    root.pwSource.audio.muted = !root.pwSource.audio.muted
                            }
                        }

                        NText {
                            text: root.pwSource && root.pwSource.ready ? root.pwSource.description : ""
                            width: parent.width - 22 - parent.spacing
                            elide: Text.ElideRight
                            color: Colors.textMuted
                            pointSize: Style.fontSizeXS
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }

                    NSlider {
                        width: parent.width
                        from: 0
                        to: 1.0
                        value: root.pwSource && root.pwSource.ready ? root.pwSource.audio.volume : 0
                        onMoved: {
                            if (root.pwSource)
                                root.pwSource.audio.volume = value
                        }
                    }
                }
            }

            Row {
                width: parent.width
                spacing: 10
                // Icon + slider on one row, no separate label line (unlike
                // the volume rows above, which need one to show each
                // device's own variable name) - kept deliberately compact:
                // Control Center's content is a fixed height that must
                // never scroll (see this file's own header comment), and
                // every optional row here competes for the same vertical
                // space the weather/forecast rows at the bottom need.
                visible: !!root.primaryBrightnessMonitor && root.primaryBrightnessMonitor.brightnessControlAvailable

                NIcon {
                    icon: ""
                    color: Colors.textMuted
                    pointSize: Style.fontSizeM
                    anchors.verticalCenter: parent.verticalCenter
                }

                NSlider {
                    width: parent.width - 22 - parent.spacing
                    anchors.verticalCenter: parent.verticalCenter
                    from: 0
                    to: 1.0
                    value: root.primaryBrightnessMonitor ? root.primaryBrightnessMonitor.brightness : 0
                    onMoved: BrightnessService.setBrightness(value)
                }
            }
                }
            }

            // Individual, always-visible circular buttons (matching the
            // header's Settings/Power/Close button look - plain
            // NIconButton defaults, a real filled pill background rather
            // than the old shared-pill-with-transparent-icons grouping)
            // rather than grouped pill containers - per explicit request
            // ("actual individual buttons similar to the settings, power,
            // close at the top"), in this left-to-right order: Ethernet,
            // Wifi, Wallpaper, Battery, Notifications, Screenshot, Night
            // Light, Stay Awake, Clipboard. Airplane Mode and Power
            // Profile were both here too at one point - Airplane Mode
            // moved to its own spot atop NetworkPanel.qml's flyout
            // instead (redundant sitting right next to Ethernet/Wifi,
            // which already toggle individually - a better fit grouped
            // with the rest of that panel's own network controls), and
            // Power Profile was dropped entirely (power-profiles-daemon
            // isn't installed on this machine, so it never did anything
            // real here) - both per explicit request. Every remaining
            // button here is unconditionally visible -
            // the Settings tab that used to gate a few of them
            // (Ethernet/Wifi/Night Light/Clipboard's old inControlCenter
            // flag) has been removed entirely, since toggling a module
            // off there had started silently hiding it from this fixed,
            // non-reorderable row - a confusing interaction once the row
            // stopped being reorderable at all (see Settings.qml's own
            // General tab for where that tab's still-relevant gauge
            // toggles moved to).
            //
            // Its own offset-background card too now, matching every
            // other section (same Colors.pill treatment as the status/
            // audio card and the weather card) - per explicit request to
            // give the "Quick Access" row the same background as
            // everything else, instead of sitting bare on the panel.
            Rectangle {
                width: root.contentWidth
                height: 34 + 24
                radius: Style.radiusS
                color: Colors.pill

                Row {
                    anchors.centerIn: parent
                    spacing: 8

                    // Ethernet - toggle-driven (nmcli), so it keeps the
                    // Loader/Component pattern rather than a plain
                    // NIconButton (its glyph/color depend on live
                    // connection state) - but the wrapper's own background
                    // is now always Colors.pill/pillActive (a real button)
                    // instead of transparent-until-hovered, matching every
                    // other button in this row.
                    Item {
                        id: networkTile
                        width: 34
                        height: 34
                        clip: true

                        Rectangle {
                            anchors.fill: parent
                            radius: width / 2
                            color: networkTileArea.containsMouse ? Colors.pillActive : Colors.pill
                            border.width: Style.borderS
                            border.color: Colors.textMuted
                            Behavior on color { ColorAnimation { duration: Style.animationFast } }
                        }

                        Loader {
                            id: networkLoader
                            anchors.centerIn: parent
                            sourceComponent: networkIconComponent
                        }

                        MouseArea {
                            id: networkTileArea
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: {
                                TooltipService.hide(networkTile)
                                if (networkLoader.item && networkLoader.item.toggle)
                                    networkLoader.item.toggle()
                            }
                            onEntered: TooltipService.show(networkTile, "Ethernet", "auto")
                            onExited: TooltipService.hide(networkTile)
                        }
                    }

                    // Wifi - same toggle-driven pattern as Ethernet above.
                    Item {
                        id: wifiTile
                        width: 34
                        height: 34
                        clip: true

                        Rectangle {
                            anchors.fill: parent
                            radius: width / 2
                            color: wifiTileArea.containsMouse ? Colors.pillActive : Colors.pill
                            border.width: Style.borderS
                            border.color: Colors.textMuted
                            Behavior on color { ColorAnimation { duration: Style.animationFast } }
                        }

                        Loader {
                            id: wifiLoader
                            anchors.centerIn: parent
                            sourceComponent: wifiIconComponent
                        }

                        MouseArea {
                            id: wifiTileArea
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: {
                                TooltipService.hide(wifiTile)
                                if (wifiLoader.item && wifiLoader.item.toggle)
                                    wifiLoader.item.toggle()
                            }
                            onEntered: TooltipService.show(wifiTile, "Wifi", "auto")
                            onExited: TooltipService.hide(wifiTile)
                        }
                    }

                    // Wallpaper - a one-off action (opens the wallpaper
                    // picker), no on/off state to reflect, so it's a plain
                    // NIconButton using its own theme-driven defaults
                    // (colorBg: Colors.mSurfaceVariant/pill, colorFg:
                    // Colors.mPrimary, colorBgHover: Colors.mHover/
                    // pillActive) - the exact same look the header's
                    // Settings/Power/Close buttons already use, just at
                    // this row's larger 34px size.
                    NIconButton {
                        baseSize: 34
                        customIconPointSize: 15
                        tooltipText: "Wallpaper"
                        icon: ""
                        onClicked: WallpaperPickerPanelState.visible = !WallpaperPickerPanelState.visible
                    }

                    // Battery - navigates to Settings' Battery tab, same
                    // as before (it isn't a toggle, there's nothing to
                    // switch on/off).
                    NIconButton {
                        baseSize: 34
                        customIconPointSize: 15
                        visible: BatteryService.batteryPresent
                        tooltipText: "Battery"
                        icon: BatteryService.batteryIcon
                        // Reported live as visibly off-center to the
                        // right - the fa-battery-* glyphs (see
                        // BatteryService.qml's getIcon()) are noticeably
                        // wider/more asymmetric than most icons in this
                        // row, the same category of real ink-vs-layout-
                        // box offset NIconButton's iconOffsetX exists for
                        // (see its own header comment - the Settings
                        // gear/Power Profile buttons needed the same fix).
                        // Was -3 (a first-pass guess) - reported live as
                        // still needing another 1-1.5px further left.
                        iconOffsetX: -4.5
                        onClicked: {
                            SettingsState.requestedCategory = "battery"
                            SettingsState.targetItem = ControlCenterState.barItem
                            ControlCenterState.visible = false
                            SettingsState.visible = true
                        }
                    }

                    // Notifications - Do Not Disturb, via dunst
                    // (Dnd.qml/DndState.qml) - added per explicit request,
                    // the first Control-Center presence for this toggle
                    // since it moved onto the bar's own notification bell
                    // icon (see ModulesConfig.qml's own comment on that
                    // move) - both now expose the same toggle independently.
                    Item {
                        id: dndTile
                        width: 34
                        height: 34
                        clip: true

                        Rectangle {
                            anchors.fill: parent
                            radius: width / 2
                            color: dndTileArea.containsMouse ? Colors.pillActive : Colors.pill
                            border.width: Style.borderS
                            border.color: Colors.textMuted
                            Behavior on color { ColorAnimation { duration: Style.animationFast } }
                        }

                        Loader {
                            id: dndLoader
                            anchors.centerIn: parent
                            sourceComponent: dndIconComponent
                        }

                        MouseArea {
                            id: dndTileArea
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: {
                                TooltipService.hide(dndTile)
                                if (dndLoader.item && dndLoader.item.toggle)
                                    dndLoader.item.toggle()
                            }
                            onEntered: TooltipService.show(dndTile, "Notifications", "auto")
                            onExited: TooltipService.hide(dndTile)
                        }
                    }

                    // Screenshot - a one-off action, same as Wallpaper.
                    NIconButton {
                        baseSize: 34
                        customIconPointSize: 15
                        tooltipText: "Screenshot (right-click: full screen)"
                        icon: ""
                        onClicked: {
                            const script = Quickshell.env("HOME") + "/.config/zaris/screenshot.sh"
                            Quickshell.execDetached([script, "region", DefaultsConfig.screenshotFolder])
                        }
                        onRightClicked: {
                            const script = Quickshell.env("HOME") + "/.config/zaris/screenshot.sh"
                            Quickshell.execDetached([script, "full", DefaultsConfig.screenshotFolder])
                        }
                    }

                    // Night Light - same toggle-driven pattern as Ethernet/
                    // Wifi/Notifications above.
                    Item {
                        id: nightLightTile
                        width: 34
                        height: 34
                        clip: true

                        Rectangle {
                            anchors.fill: parent
                            radius: width / 2
                            color: nightLightTileArea.containsMouse ? Colors.pillActive : Colors.pill
                            border.width: Style.borderS
                            border.color: Colors.textMuted
                            Behavior on color { ColorAnimation { duration: Style.animationFast } }
                        }

                        Loader {
                            id: nightLightLoader
                            anchors.centerIn: parent
                            sourceComponent: nightLightIconComponent
                        }

                        MouseArea {
                            id: nightLightTileArea
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: {
                                TooltipService.hide(nightLightTile)
                                if (nightLightLoader.item && nightLightLoader.item.toggle)
                                    nightLightLoader.item.toggle()
                            }
                            onEntered: TooltipService.show(nightLightTile, "Night Light", "auto")
                            onExited: TooltipService.hide(nightLightTile)
                        }
                    }

                    // Stay Awake - same toggle-driven pattern as Ethernet/
                    // Wifi/Notifications/Night Light above, added per
                    // explicit request ("lets also add another button
                    // there for stay awake... have it operate similarly
                    // to how DND does" - StayAwake.qml's own icon, one
                    // fixed glyph with color-only state, no text label).
                    Item {
                        id: stayAwakeTile
                        width: 34
                        height: 34
                        clip: true

                        Rectangle {
                            anchors.fill: parent
                            radius: width / 2
                            color: stayAwakeTileArea.containsMouse ? Colors.pillActive : Colors.pill
                            border.width: Style.borderS
                            border.color: Colors.textMuted
                            Behavior on color { ColorAnimation { duration: Style.animationFast } }
                        }

                        Loader {
                            id: stayAwakeLoader
                            anchors.centerIn: parent
                            sourceComponent: stayAwakeIconComponent
                        }

                        MouseArea {
                            id: stayAwakeTileArea
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: {
                                TooltipService.hide(stayAwakeTile)
                                if (stayAwakeLoader.item && stayAwakeLoader.item.toggle)
                                    stayAwakeLoader.item.toggle()
                            }
                            onEntered: TooltipService.show(stayAwakeTile, "Stay Awake", "auto")
                            onExited: TooltipService.hide(stayAwakeTile)
                        }
                    }

                    // Clipboard - opens the clipboard history panel, no
                    // on/off state to reflect, so it's a plain NIconButton
                    // like Wallpaper/Screenshot above rather than the
                    // Loader/toggle() pattern.
                    NIconButton {
                        baseSize: 34
                        customIconPointSize: 15
                        tooltipText: "Clipboard"
                        icon: ""
                        onClicked: ClipboardHistoryPanelState.visible = !ClipboardHistoryPanelState.visible
                    }
                }
            }

            // pointSize: 15 on all five below - originally 17
            // (Style.toOdd(34 * 0.48), the same formula NIconButton
            // itself uses for its icon at this row's baseSize: 34) so
            // these toggle-driven icons (which don't go through
            // NIconButton at all, hence no automatic match) matched the
            // plain-NIconButton icons in this same row (Wallpaper/
            // Battery/Power Profile/Screenshot/Clipboard) rather than
            // their bar-module default (Style.fontSizeL, noticeably
            // smaller). Both sets then trimmed down together to 15 -
            // reported live as sitting too close to the buttons' own
            // circular border at 17 - see each plain NIconButton's own
            // customIconPointSize override below for the other half of
            // that same shrink.
            Component {
                id: networkIconComponent
                NetworkToggle {
                    clickable: false
                    textColor: Colors.textMuted
                    activeColor: Colors.blue
                    pointSize: 15
                }
            }

            Component {
                id: wifiIconComponent
                WifiToggle {
                    clickable: false
                    textColor: Colors.textMuted
                    activeColor: Colors.blue
                    pointSize: 15
                }
            }

            Component {
                id: nightLightIconComponent
                NightLight {
                    clickable: false
                    textColor: Colors.textMuted
                    activeColor: Colors.blue
                    pointSize: 15
                }
            }

            Component {
                id: stayAwakeIconComponent
                StayAwake {
                    clickable: false
                    textColor: Colors.textMuted
                    activeColor: Colors.coral
                    pointSize: 15
                }
            }

            Component {
                id: dndIconComponent
                Dnd {
                    clickable: false
                    // Primary -> secondary when toggled on, rather than
                    // this row's usual muted/accent pairing - per
                    // explicit request ("that icon needs to match the
                    // color palette... maybe it goes from the primary
                    // color to secondary when turned on").
                    textColor: Colors.blue
                    activeColor: Colors.teal
                    pointSize: 15
                }
            }


            // Weather - the one piece of the reference screenshot deferred
            // out of the seventh Control Center pass specifically so it
            // wouldn't be bundled into an already-large media/audio change.
            // No ModulesConfig inControlCenter gate - unlike the toggle/quick-launch
            // tiles above, there's no existing bar presence to preserve or
            // hide, and a location/weather API is opt-in by nature (simply
            // shows "Loading weather..." until the first fetch resolves,
            // never a silent failure). Now WeatherWidget.qml, shared with
            // CalendarFlyout.qml's own weather row rather than duplicated -
            // the offset-background card here is applied at this call
            // site, not inside WeatherWidget.qml itself, since that
            // component is also embedded in CalendarFlyout.qml's own
            // popup, which already has its own different background
            // treatment and shouldn't inherit a card it never asked for.
            Rectangle {
                width: root.contentWidth
                height: weatherWidget.implicitHeight + 24
                radius: Style.radiusS
                color: Colors.pill

                WeatherWidget {
                    id: weatherWidget
                    anchors.centerIn: parent
                    width: parent.width - 24
                }
            }

            // Was a plain Row (media card, then whichever gauges column
            // immediately follows it with a fixed 14px gap) - switched to
            // explicit left/right anchoring instead so the gauges cluster
            // sits flush against the panel's own right edge, matching the
            // Noctalia reference layout, rather than hugging the media
            // card's own right edge with ~100px of dead space beyond it
            // (contentWidth 380 - mediaCard's 230 - the gauges' own ~38px
            // width left a gap that wide). Reported live as "bump the 4
            // circular readings more to the right."
            Item {
                width: root.contentWidth
                height: Math.max(nowPlayingCard.height, gaugesCard.height)

                // "Now Playing" - its own offset-background card too
                // (same Colors.pill treatment as every other section),
                // wrapping both the real media-playing Column below and
                // its "No Media Playing" placeholder sibling (mutually
                // exclusive visible: bindings, so only one ever actually
                // renders inside this shared card at a time) - per
                // explicit request to give this section the same
                // background the audio/status and weather cards already
                // have.
                Rectangle {
                    id: nowPlayingCard
                    anchors.left: parent.left
                    // Both this card and gaugesCard vertically center
                    // within their shared parent Item (whose own height
                    // is the taller of the two) rather than top-aligning
                    // - reported live as Now Playing needing to "move
                    // down a little" to line up with the gauges, which
                    // varied in height (noMediaCard's placeholder state
                    // is noticeably shorter than the full mediaCard, and
                    // could be taller or shorter than gaugesCard
                    // depending on which optional gauges are enabled) so
                    // a fixed pixel offset wouldn't stay correct across
                    // every state - centering both against the shared
                    // parent keeps them aligned regardless.
                    anchors.verticalCenter: parent.verticalCenter
                    width: 290 + 24
                    height: (mediaCard.visible ? mediaCard.height : noMediaCard.height) + 24
                    radius: Style.radiusS
                    color: Colors.pill

                Column {
                    id: mediaCard
                    anchors.centerIn: parent
                    // Was 230 - widened now that the gauges cluster sits
                    // flush against the panel's own right edge instead of
                    // immediately after this card (see the Item's own
                    // comment above): left at 230 alongside that fix, this
                    // card would have had a large, obviously dead gap
                    // between its own right edge and the gauges rather
                    // than the gauges' *intended* small gap - reported
                    // live as "theres a lot of dead space there now."
                    // 290 leaves a deliberate ~52px gap before the 38px-
                    // wide gauges column (contentWidth 380 - 290 - 38).
                    width: 290
                    spacing: 8
                    // The "both places at once" exception this card used to
                    // need (Noctalia's own bar shows a compact "now playing"
                    // widget alongside this same rich card in its Control
                    // Center) no longer applies - the user asked to drop
                    // Bar.qml's MediaWidget now that this card exists,
                    // since showing the same now-playing info in both spots
                    // was redundant. `mediaPlayer`'s inControlCenter default flipped to
                    // `true` at the same time (ModulesConfig.qml), so this
                    // card is properly gated like every other tile here now.
                    visible: ModulesConfig.showInControlCenter("mediaPlayer", ControlCenterState.panel) && !!MediaService.currentPlayer

                    Item {
                        width: parent.width
                        height: 130
                        clip: true

                        Rectangle {
                            anchors.fill: parent
                            radius: Style.radiusS
                            color: Colors.pill
                        }

                        // Known caveat, not fixable from here - same family
                        // as MediaService.qml's own trackLength caveat
                        // (unreliable "generic browser" MPRIS metadata):
                        // confirmed live via direct `busctl ... Metadata`
                        // + a filesystem check that Chromium's own MPRIS
                        // bridge can report an `mpris:artUrl` pointing at a
                        // `/tmp/.org.chromium.Chromium.<id>` temp file that
                        // never actually loads. Originally chalked up to
                        // Chromium deleting the file "almost immediately" -
                        // re-investigated 2026-09-09 per an explicit user
                        // question about whether this is really a Chromium-
                        // as-Flatpak issue specifically, and it is: `flatpak
                        // info --show-permissions org.chromium.Chromium`
                        // grants `filesystems=home;` and a short allowlist
                        // of specific paths, with no `--filesystem=/tmp` (or
                        // `host`/`host-os`) anywhere in it. Flatpak's bubble-
                        // wrap sandbox gives every app a private, isolated
                        // `/tmp` by default unless a rule like that grants
                        // the real host one - so the path Chromium's MPRIS
                        // bridge advertises is real and valid *inside its
                        // own sandbox*, but `/tmp/.org.chromium.Chromium.
                        // <id>` on the actual host filesystem (what this
                        // Image, running unsandboxed, actually reads) either
                        // doesn't exist at all or is a completely unrelated
                        // file - not a timing race that just happens to
                        // always lose, but two different filesystems that
                        // only share a path string. Still not fixable from
                        // here either way (nothing server-side changes what
                        // path Chromium's MPRIS metadata reports), but this
                        // is the accurate why - a real player run outside a
                        // sandbox (mpv, VLC, Spotify's native non-Flatpak
                        // build, etc.) isn't affected, since there's no
                        // sandbox boundary for its own real temp files to
                        // cross. This Image simply fails to load and the
                        // Colors.pill/gradient background behind it shows
                        // through instead, which is the correct graceful
                        // fallback already, not a bug to chase further.
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
                            anchors.bottom: parent.bottom
                            anchors.margins: 10
                            width: parent.width - 20
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

                            NText {
                                text: MediaService.trackAlbum
                                width: parent.width
                                visible: MediaService.trackAlbum !== ""
                                elide: Text.ElideRight
                                color: Colors.textMuted
                                pointSize: Style.fontSizeXS
                            }
                        }
                    }

                    // Noctalia's own reference Control Center integrates a
                    // live audio-reactive visualizer into its media card,
                    // between the track info and the transport controls -
                    // reuses AudioVisualizer.qml exactly as it stands (the
                    // bar's own module for this), just re-sized to the
                    // card's own width rather than duplicating its
                    // Process+SplitParser capture logic a second time.
                    // Wrapped in a Loader active only while both this card
                    // (visible: ModulesConfig.showInControlCenter("mediaPlayer",...)
                    // && !!MediaService.currentPlayer, above) AND Control
                    // Center itself are actually visible - AudioVisualizer's
                    // own header comment is explicit that it carries a real,
                    // continuous cost (a `parec` capture running for as long
                    // as the component exists at all), and mediaCard.visible
                    // alone doesn't imply this popup is open (nothing
                    // unbinds it when Control Center closes while a track
                    // keeps playing) - gating on both is what actually keeps
                    // that capture from running in the background whenever
                    // something happens to be playing, whether or not
                    // anyone's looking at this panel.
                    Loader {
                        anchors.horizontalCenter: parent.horizontalCenter
                        height: active ? item.implicitHeight : 0
                        active: root.visible && mediaCard.visible
                        sourceComponent: Component {
                            AudioVisualizer {
                                barColor: Colors.coral
                                // 58 bars at this width/spacing sums to
                                // 288px - as close to this card's own 290px
                                // width as a whole bar count gets, so
                                // centering it leaves only ~1px of margin
                                // per side rather than a visibly lopsided
                                // gap.
                                barCount: 58
                                barWidth: 3
                                barSpacing: 2
                                maxBarHeight: 20
                            }
                        }
                    }

                    // Seek slider removed per explicit request - the
                    // track-position progress bar this drove
                    // (MediaService.currentPosition/trackLength) wasn't
                    // wanted here.
                    Row {
                        anchors.horizontalCenter: parent.horizontalCenter
                        spacing: 18

                        // All three transport buttons now share one
                        // baseSize (was 28/34/28 - Play/Pause sized
                        // larger than Previous/Next) - reported live as
                        // needing to "match in size."
                        NIconButton {
                            baseSize: 30
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
                            baseSize: 30
                            icon: ""
                            enabled: MediaService.canGoNext
                            onClicked: MediaService.next()
                        }
                    }
                }

                Column {
                    id: noMediaCard
                    anchors.centerIn: parent
                    width: 290 // matches mediaCard's own width - see its comment
                    spacing: 8
                    visible: ModulesConfig.showInControlCenter("mediaPlayer", ControlCenterState.panel) && !MediaService.currentPlayer

                    Item {
                        width: parent.width
                        height: 130

                        Rectangle {
                            anchors.fill: parent
                            radius: Style.radiusS
                            color: Colors.pill
                        }

                        Column {
                            anchors.centerIn: parent
                            spacing: 6

                            NIcon {
                                anchors.horizontalCenter: parent.horizontalCenter
                                icon: ""
                                color: Colors.textMuted
                                pointSize: Style.fontSizeXXXL
                            }

                            NText {
                                text: "No Media Playing"
                                anchors.horizontalCenter: parent.horizontalCenter
                                color: Colors.textMuted
                                pointSize: Style.fontSizeS
                            }
                        }
                    }
                }
                }

                // Its own offset-background card too (same Colors.pill
                // treatment as every other section) - per explicit
                // request to give the 4 usage/temp gauges the same
                // background the audio/status and weather cards already
                // have.
                Rectangle {
                    id: gaugesCard
                    anchors.right: parent.right
                    // See nowPlayingCard's own comment on why both cards
                    // vertically center against their shared parent
                    // rather than top-aligning.
                    anchors.verticalCenter: parent.verticalCenter
                    width: 38 + 24
                    height: gaugesColumn.height + 24
                    radius: Style.radiusS
                    color: Colors.pill

                Column {
                    id: gaugesColumn
                    spacing: 6
                    anchors.centerIn: parent

                    NCircularGauge {
                        diameter: 38
                        visible: ModulesConfig.configFile.adapter.ccGaugeCpu
                        value: cpuSource.percent / 100
                        valueText: Math.round(cpuSource.percent) + "%"
                        icon: ""
                        fillColor: Colors.coral
                    }

                    NCircularGauge {
                        diameter: 38
                        visible: ModulesConfig.configFile.adapter.ccGaugeCpuTemp
                        value: cpuTempSource.tempC / 100
                        valueText: cpuTempSource.haveReading ? Math.round(cpuTempSource.tempC) + "°" : "--"
                        icon: ""
                        fillColor: Colors.blue
                    }

                    // Was the exact same thermometer glyph the CPU-temp
                    // gauge above uses - the two gauges were indistinguishable
                    // by icon shape, only their fillColor (blue vs teal) told
                    // them apart. nf-md-expansion_card (U+F0A32, confirmed
                    // present in the installed font before use, same as its
                    // bar-module counterpart in BarStatusModules.qml) ties
                    // this reading to its actual hardware instead.
                    NCircularGauge {
                        diameter: 38
                        visible: ModulesConfig.configFile.adapter.ccGaugeGpuTemp
                        value: gpuTempSource.tempC / 100
                        valueText: gpuTempSource.haveReading ? Math.round(gpuTempSource.tempC) + "°" : "--"
                        icon: "󰨲"
                        fillColor: Colors.teal
                    }

                    NCircularGauge {
                        diameter: 38
                        visible: ModulesConfig.configFile.adapter.ccGaugeRam
                        value: memSource.percent / 100
                        valueText: Math.round(memSource.percent) + "%"
                        icon: "󰍛"
                        fillColor: Colors.purple
                    }
                }
                }
            }
        }
    }
}
