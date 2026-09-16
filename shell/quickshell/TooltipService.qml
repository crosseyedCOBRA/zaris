pragma Singleton
import QtQuick
import Quickshell

// Shared tooltip service - adapted from Noctalia's Services/UI/
// TooltipService.qml (MIT licensed, v4.7.7 - see README.md's "Third-party
// code" section), stripped of `Settings.data.ui.tooltipsEnabled` (no
// per-user settings persistence here - always enabled) and `Logger.*`
// calls (no such logging singleton in Zaris). Tooltip support (a
// `tooltipText` property plus the hover-triggered show()/hide() calls) was
// restored via this file/Tooltip.qml for NButton/NIconButton/NTabButton/
// NSettingsIndicator, which had it stripped out during the earlier
// widget-library port (neither file existed yet at the time).
//
// One persistent Tooltip instance, reused for every hover target - was a
// fresh Tooltip PopupWindow created via Component.createObject() and
// destroyed again on every single show() call (matching upstream's own
// per-call create/destroy approach, on the theory that tooltips are short-
// lived and infrequent enough that a pool wasn't worth it). Reported live,
// repeatedly, as Control Center's tooltips "flickering" on hover - two
// rounds of hardening the show()/hide() state machine itself (debouncing
// same-target re-entry, then fixing a reproduced bug where switching
// targets synchronously hid whatever was currently showing even though
// the replacement wouldn't be ready for another ~1s) were each verified
// correct via live-captured logs (a real, stable single show/hide cycle,
// zero repeated calls) but the user still saw visible flicker while
// watching a scripted hover live afterward - meaning the show()/hide()
// *logic* was never actually the remaining cause. The one thing neither
// round touched: a genuinely new X11 window still got created and mapped
// on every hover onto a *new* target, and window creation/mapping is
// exactly the kind of operation that can produce a visible first-frame
// flash independent of any QML-level state bug. A single persistent
// window, just repositioned/retargeted/re-content-ed for each new hover,
// removes that window churn entirely - there's only ever one Tooltip
// window for the whole shell's lifetime now.
Singleton {
    id: root

    property Tooltip tooltip: Tooltip {}

    function show(target, content, direction, delay) {
        if (!target || !content || content === "")
            return
        tooltip.show(target, content, direction || "auto", delay !== undefined ? delay : Style.tooltipDelay)
    }

    function hide(target) {
        if (target && tooltip.targetItem !== target)
            return
        tooltip.hide()
    }

    function hideImmediately() {
        tooltip.hideImmediately()
    }
}
