pragma Singleton
import QtQuick

// Shared palette so every part of the shell (bar, launcher, OSD, flyout,
// settings window) looks like one consistent thing rather than several.
// ~/.config/dunst/dunstrc and ~/.config/rofi/theme.rasi are themed to match
// these same values by hand -- they can't import this file, so keep them in
// sync manually if you change a color here.
//
// bg/text/blue/teal/coral are sourced from ThemeConfig.qml (backed by
// ~/.config/quickshell/colors.json, editable via Settings' Colors tab or by
// hand) instead of being hardcoded - every file below and throughout the
// rest of the shell already references these exact names, so a theme
// change (or a built-in preset) propagates everywhere automatically with
// no other file needing to change.
//
// pill/pillActive - the "raised surface" tone behind every button/card/
// chip/pill throughout the shell (Control Center's toggle pills and
// section cards, Settings' chips, the media card, ...) - used to be
// hardcoded navy-blue hex literals regardless of theme, reported live as
// a real, visible mismatch on any non-default palette ("statically coded
// bits of Blue" that didn't follow the chosen theme). Now derived from
// `bg` itself (lightened, hue/saturation preserved via HSL) rather than a
// second pair of fixed constants, so a differently-hued background (e.g.
// Dracula's purple-leaning `#282a36`) produces a correspondingly-hued
// lighter surface instead of staying stuck on the default's navy. `bg`
// itself is typically near-black (very low HSL lightness), where Qt's own
// multiplicative Qt.lighter() barely moves a value that close to zero -
// added lightness (not scaled lightness) is what actually reads as a
// visibly raised surface at that starting point.
// red stays fixed, deliberately out of scope (a genuine semantic danger/
// error color - many design systems keep this constant across themes on
// purpose, so it still reads as "alarm" regardless of the chosen palette)
// - see ROADMAP.md's "per-module color overrides" backlog item for a
// possible future extension covering it too.
QtObject {
    readonly property color _pillBase: Qt.color(ThemeConfig.background)
    function _lighten(base, amount) {
        return Qt.hsla(base.hslHue, base.hslSaturation, Math.min(1.0, base.hslLightness + amount), 1.0)
    }

    // Linear RGB blend toward `target` by `t` (0 = pure `base`, 1 = pure
    // `target`) - used below to derive textMuted from text/bg rather than
    // a third fixed constant.
    function _blend(base, target, t) {
        return Qt.rgba(base.r + (target.r - base.r) * t, base.g + (target.g - base.g) * t, base.b + (target.b - base.b) * t, 1.0)
    }

    // Rotates `base`'s hue by `degrees` (wrapping around 360°), keeping
    // its own saturation/lightness - used below to derive purple as a
    // "related but distinct" 4th accent from primary, at the same ~72°
    // offset the previous fixed default pair (#5b7fd6 primary / #b882be
    // purple) happened to sit at, rather than a second independently
    // fixed hex value.
    function _hueShift(base, degrees) {
        let h = (base.hslHue * 360 + degrees) % 360
        if (h < 0)
            h += 360
        return Qt.hsla(h / 360, base.hslSaturation, base.hslLightness, 1.0)
    }

    readonly property string bg: ThemeConfig.background
    // Bar.qml's own background - separate from bg so the bar can have a
    // distinct color from every other panel/popup (Settings, Control
    // Center, the calendar flyout, etc., which all still use bg directly).
    // Falls back to bg whenever ThemeConfig.barBackground is unset (the
    // default - most users want the bar to just match everything else).
    readonly property string barBg: ThemeConfig.barBackground || ThemeConfig.background
    readonly property color pill: _lighten(_pillBase, 0.10)
    readonly property color pillActive: _lighten(_pillBase, 0.18)
    readonly property string text: ThemeConfig.text
    // Was a fixed "#8890b5" regardless of theme - reported live as one of
    // the remaining "doesn't match the palette" spots (this is the
    // textColor/border tone for most bar-widget icons and the CC toggle
    // tiles' own border, so a mismatch here was visible almost
    // everywhere). Blended 40% of the way from `text` toward `bg` instead,
    // landing close to the old default's own lightness for the stock
    // theme while actually tracking a different theme's text/background
    // pair.
    readonly property color textMuted: _blend(Qt.color(text), Qt.color(bg), 0.4)
    readonly property string teal: ThemeConfig.secondary
    readonly property string blue: ThemeConfig.primary
    // Was a fixed "#b882be" - the 4th accent used for a handful of
    // one-off spots (Volume, Notifications, the RAM gauge, ...) needing
    // visual distinction from primary/secondary/tertiary. Hue-shifted off
    // `blue` (primary) instead of pinned, so it still reads as a
    // related-but-different accent under any theme rather than staying
    // stuck on the default's own magenta regardless of what's chosen.
    readonly property color purple: _hueShift(Qt.color(blue), 72)
    readonly property string coral: ThemeConfig.tertiary
    readonly property string red: "#d9556a"

    // Material Design 3 role aliases, adapted from Noctalia's Color.qml (MIT
    // licensed, github.com/noctalia-dev/noctalia @ v4.7.7 - see README.md's
    // "Third-party code" section) so ported Noctalia widgets that reference
    // `Color.mPrimary` etc. have something to bind to, without dragging in
    // their dynamic wallpaper-based color generation or live theme-switch
    // transition animations (Zaris's palette is a fixed set of constants,
    // never reassigned at runtime, so there's nothing to animate between).
    // Existing files keep using the flat names above directly - these are
    // purely additive, mapped onto them rather than replacing them:
    //   mPrimary/mSecondary/mTertiary - the three accent colors already in
    //     rotation across bar widgets (blue is the most-repeated accent, so
    //     it gets "primary"; teal and coral fill secondary/tertiary)
    //   mError - genuinely new; nothing above was a real alarm/danger red
    //     (coral reads more salmon than alarm), so `red` is a new base color
    //   mSurface/mSurfaceVariant - the two background tones already used
    //     for panels (bg) and cards/pills (pill)
    //   mOutline - textMuted, already used as the border color everywhere
    //   mHover - pillActive, already used for hover/active highlight fills
    //   mOn* - text or textMuted, whichever already reads correctly against
    //     that surface in the existing UI
    readonly property color mPrimary: blue
    readonly property color mOnPrimary: text
    readonly property color mSecondary: teal
    readonly property color mOnSecondary: text
    readonly property color mTertiary: coral
    readonly property color mOnTertiary: text
    readonly property color mError: red
    readonly property color mOnError: text
    readonly property color mSurface: bg
    readonly property color mOnSurface: text
    readonly property color mSurfaceVariant: pill
    readonly property color mOnSurfaceVariant: textMuted
    readonly property color mOutline: textMuted
    readonly property color mShadow: bg
    readonly property color mHover: pillActive
    readonly property color mOnHover: text

    // Resolves a user-facing "color key" (as used by e.g. a color-choice
    // picker) to an actual color/on-color pair - adapted from Noctalia's
    // same-named functions, dropping the "none" special-case tie to their
    // own capsule-color feature (callers here just treat an unrecognized
    // key as onSurface/surface, matching their own fallback branch).
    function resolveColorKey(key) {
        switch (key) {
        case "primary": return mPrimary
        case "secondary": return mSecondary
        case "tertiary": return mTertiary
        case "error": return mError
        default: return mOnSurface
        }
    }

    function resolveOnColorKey(key) {
        switch (key) {
        case "primary": return mOnPrimary
        case "secondary": return mOnSecondary
        case "tertiary": return mOnTertiary
        case "error": return mOnError
        default: return mSurface
        }
    }

    function resolveColorKeyOptional(key) {
        switch (key) {
        case "primary": return mPrimary
        case "secondary": return mSecondary
        case "tertiary": return mTertiary
        case "error": return mError
        default: return "transparent"
        }
    }

    readonly property var colorKeyModel: [
        { key: "none", name: "None" },
        { key: "primary", name: "Primary" },
        { key: "secondary", name: "Secondary" },
        { key: "tertiary", name: "Tertiary" },
        { key: "error", name: "Error" }
    ]
}
